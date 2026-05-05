import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// Result type returned by all [PhotoUploadHandler] operations.
class PhotoUploadResult {
  /// The updated list of image URLs from the server (non-null on success).
  final List<String>? imageUrls;

  /// Human-readable message from the server (success or error text).
  final String message;

  /// Whether the operation completed without error.
  final bool success;

  const PhotoUploadResult._({
    required this.success,
    required this.message,
    this.imageUrls,
  });

  factory PhotoUploadResult.success({
    required String message,
    required List<String> imageUrls,
  }) => PhotoUploadResult._(
    success: true,
    message: message,
    imageUrls: imageUrls,
  );

  factory PhotoUploadResult.failure(String message) =>
      PhotoUploadResult._(success: false, message: message);
}

/// Stateless utility for all photo HTTP operations:
///  - [uploadPhotos]     — multipart POST of one or more new images
///  - [deletePhoto]      — DELETE a single image by index
///  - [deleteAllExtras]  — DELETE indices 1…n-1, keeping the profile picture
///
/// No widget code; callers handle setState / snackbars.
class PhotoUploadHandler {
  final String userId;

  const PhotoUploadHandler({required this.userId});

  // ---------------------------------------------------------------------------
  // Token helper
  // ---------------------------------------------------------------------------

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  /// Upload [images] via multipart POST. Returns the server's updated image
  /// list on success, or a failure result describing the error.
  Future<PhotoUploadResult> uploadPhotos(
    List<File> images, {
    required String noTokenMessage,
    required String fileTooLargeMessage,
    required String unsupportedFormatPrefix,
    required String failedMessage,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return PhotoUploadResult.failure(noTokenMessage);
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Endpoints.baseURL}auth/users/$userId/photos'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    for (final imageFile in images) {
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return PhotoUploadResult.failure(fileTooLargeMessage);
      }

      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = _mimeType(extension);
      if (mimeType == null) {
        return PhotoUploadResult.failure(
          '$unsupportedFormatPrefix: $extension',
        );
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final urls = data['images'] != null
            ? List<String>.from(data['images'] as List)
            : <String>[];
        return PhotoUploadResult.success(
          message: (data['message'] as String?) ?? '',
          imageUrls: urls,
        );
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        return PhotoUploadResult.failure(
          (errorData['error'] as String?) ?? failedMessage,
        );
      }
    } catch (_) {
      return PhotoUploadResult.failure(failedMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete single
  // ---------------------------------------------------------------------------

  /// Delete the image at [index]. Returns the updated image list on success.
  Future<PhotoUploadResult> deletePhoto(
    int index, {
    required String noTokenMessage,
    required String failedMessage,
    required String defaultSuccessMessage,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return PhotoUploadResult.failure(noTokenMessage);
    }

    try {
      final response = await http.delete(
        Uri.parse('${Endpoints.baseURL}auth/users/$userId/photo/$index'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final urls = data['images'] != null
            ? List<String>.from(data['images'] as List)
            : null;
        return PhotoUploadResult.success(
          message: (data['message'] as String?) ?? defaultSuccessMessage,
          imageUrls: urls ?? [],
        );
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        return PhotoUploadResult.failure(
          (errorData['error'] as String?) ?? failedMessage,
        );
      }
    } catch (_) {
      return PhotoUploadResult.failure(failedMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete all extras (keep index 0)
  // ---------------------------------------------------------------------------

  /// Deletes indices [existingCount-1] down to 1, keeping the profile picture
  /// at index 0. Then re-fetches the user to get the authoritative list.
  ///
  /// Returns the server's updated image list (or a best-effort local list of
  /// just the first image if the re-fetch fails).
  Future<PhotoUploadResult> deleteAllExtras({
    required int existingCount,
    required String noTokenMessage,
    required String failedMessage,
    required String successMessage,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return PhotoUploadResult.failure(noTokenMessage);
    }

    try {
      for (int i = existingCount - 1; i >= 1; i--) {
        await http.delete(
          Uri.parse('${Endpoints.baseURL}auth/users/$userId/photo/$i'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      // Re-fetch to get the authoritative list.
      final getUserResponse = await http.get(
        Uri.parse('${Endpoints.baseURL}auth/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getUserResponse.statusCode == 200) {
        final userData =
            json.decode(getUserResponse.body) as Map<String, dynamic>;
        final urls = userData['images'] != null
            ? List<String>.from(userData['images'] as List)
            : <String>[];
        return PhotoUploadResult.success(
          message: successMessage,
          imageUrls: urls,
        );
      } else {
        // Best-effort: report success with a locally-trimmed list.
        return PhotoUploadResult.success(
          message: successMessage,
          imageUrls: [],
        );
      }
    } catch (_) {
      return PhotoUploadResult.failure(failedMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static String? _mimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}
