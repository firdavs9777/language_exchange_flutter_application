import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class MediaService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Send a message with media (image, audio, video, document)
  /// Returns the created message data
  static Future<Map<String, dynamic>> sendMessageWithMedia({
    required String receiverId,
    String? messageText,
    required File mediaFile,
    String? mediaType, // 'image', 'audio', 'video', 'document'
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add fields
      request.fields['receiver'] = receiverId;
      if (messageText != null && messageText.isNotEmpty) {
        request.fields['message'] = messageText;
      }

      // Determine media type from file extension if not provided
      String? detectedMediaType = mediaType;
      if (detectedMediaType == null) {
        final extension = mediaFile.path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          detectedMediaType = 'image';
        } else if (['mp3', 'm4a', 'wav', 'aac'].contains(extension)) {
          detectedMediaType = 'audio';
        } else if (['mp4', 'mov', 'avi'].contains(extension)) {
          detectedMediaType = 'video';
        } else {
          detectedMediaType = 'document';
        }
      }

      // Get file name
      final fileName = mediaFile.path.split('/').last;
      
      // Determine MIME type from file extension
      // The backend validates based on MIME type, so we need to set it correctly
      final extension = fileName.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream'; // Default
      
      // Map extensions to MIME types
      switch (extension) {
        // Images
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'heic':
        case 'heif':
          mimeType = 'image/heic';
          break;
        case 'bmp':
          mimeType = 'image/bmp';
          break;
        // Audio
        case 'mp3':
          mimeType = 'audio/mpeg';
          break;
        case 'm4a':
          mimeType = 'audio/mp4';
          break;
        case 'wav':
          mimeType = 'audio/wav';
          break;
        case 'aac':
          mimeType = 'audio/aac';
          break;
        case 'ogg':
          mimeType = 'audio/ogg';
          break;
        case 'flac':
          mimeType = 'audio/flac';
          break;
        // Video
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        case 'avi':
          mimeType = 'video/x-msvideo';
          break;
        case 'mkv':
          mimeType = 'video/x-matroska';
          break;
        case 'webm':
          mimeType = 'video/webm';
          break;
        // Documents
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'doc':
          mimeType = 'application/msword';
          break;
        case 'docx':
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'txt':
          mimeType = 'text/plain';
          break;
      }

      // Add file with explicit MIME type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          mediaFile.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Message sent successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send media message',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Send a message with location
  static Future<Map<String, dynamic>> sendMessageWithLocation({
    required String receiverId,
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
    String? messageText,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiver': receiverId,
          if (messageText != null && messageText.isNotEmpty) 'message': messageText,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            if (address != null) 'address': address,
            if (placeName != null) 'placeName': placeName,
          },
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Location shared successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to share location',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Validate file size and type
  /// Note: We do basic validation here, but the backend has the final say
  static Map<String, dynamic> validateMediaFile(File file, String? mediaType) {
    try {
      final fileSize = file.lengthSync();
      final extension = file.path.split('.').last.toLowerCase();

      // Determine media type
      String? detectedType = mediaType;
      if (detectedType == null) {
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'].contains(extension)) {
          detectedType = 'image';
        } else if (['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'].contains(extension)) {
          detectedType = 'audio';
        } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
          detectedType = 'video';
        } else {
          // For documents, be more lenient - let backend decide
          detectedType = 'document';
        }
      }

      // Validate file size (basic check)
      int maxSize;
      switch (detectedType) {
        case 'image':
          maxSize = 10 * 1024 * 1024; // 10MB
          break;
        case 'audio':
          maxSize = 25 * 1024 * 1024; // 25MB
          break;
        case 'video':
          maxSize = 100 * 1024 * 1024; // 100MB
          break;
        case 'document':
          maxSize = 50 * 1024 * 1024; // 50MB
          break;
        default:
          maxSize = 10 * 1024 * 1024; // Default 10MB
      }

      if (fileSize > maxSize) {
        final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
        return {
          'valid': false,
          'error': 'File size exceeds maximum allowed size of ${maxSizeMB}MB for $detectedType files',
        };
      }

      // Don't validate file extension strictly - let backend handle it
      // The backend will reject invalid types with a proper error message
      return {
        'valid': true,
        'mediaType': detectedType,
        'fileSize': fileSize,
      };
    } catch (e) {
      // If validation fails, still allow upload and let backend decide
      return {
        'valid': true,
        'mediaType': mediaType ?? 'document',
        'fileSize': 0,
      };
    }
  }
}

