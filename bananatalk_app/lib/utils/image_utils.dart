import 'package:bananatalk_app/service/endpoints.dart';

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
  static String normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // If it's already a full URL (starts with http:// or https://), return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If it starts with /, it's a relative path - construct full URL
    if (url.startsWith('/')) {
      return '$baseServerUrl$url';
    }

    // If it doesn't start with /, assume it's a filename in /uploads
    // Ensure the path starts with /uploads/
    if (!url.startsWith('uploads/') && !url.startsWith('/uploads/')) {
      return '$baseServerUrl/uploads/$url';
    }
    return '$baseServerUrl/$url';
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
}

