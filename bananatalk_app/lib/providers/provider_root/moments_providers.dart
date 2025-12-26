import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MomentsService {
  int count = 0;

  // Updated getMoments with pagination support
  Future<Map<String, dynamic>> getMoments(
      {int page = 1, int limit = 10}) async {
    // Enforce max limit of 50 per page
    if (limit > 50) {
      limit = 50;
    }

    final response = await http.get(Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}?page=$page&limit=$limit'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> momentsList = data['moments'] ?? [];
      final pagination = data['pagination'] ?? {};

      return {
        'moments':
            momentsList.map((postJson) => Moments.fromJson(postJson)).toList(),
        'pagination': pagination,
      };
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 
                          errorData['message'] ?? 
                          'Failed to load moments';
      
      // Log the actual backend error for debugging
      print('❌ Backend error loading moments: $errorMessage');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      throw Exception(errorMessage);
    }
  }

  Future<List<Moments>> getMomentsUser({required String id, int page = 1, int limit = 10}) async {
    // Enforce max limit of 50 per page
    if (limit > 50) {
      limit = 50;
    }

    final response = await http.get(Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/user/$id?page=$page&limit=$limit'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> momentsList = data['data'] ?? [];
        count = data['count'] ?? 0;
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('count', count.toString());
        
        return momentsList.map((json) => Moments.fromJson(json)).toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to load user moments');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to load user moments');
    }
  }

  Future<Moments> createMoments({
    required String title,
    required String description,
    String privacy = 'public',
    String category = 'general',
    String language = 'en',
    String? mood,
    List<String>? tags,
    String? scheduledFor,
    Map<String, dynamic>? location,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    // Build the request body - DO NOT include 'user' field (backend uses authenticated user from token)
    final Map<String, dynamic> body = {
      'title': title.trim(),
      'description': description.trim(),
      'privacy': privacy,
      'category': category,
      'language': language,
    };

    // Add optional fields only if they have values
    if (mood != null && mood.isNotEmpty) {
      body['mood'] = mood;
    }
    if (tags != null && tags.isNotEmpty) {
      // Enforce max 5 tags
      body['tags'] = tags.take(5).toList();
    }
    if (scheduledFor != null && scheduledFor.isNotEmpty) {
      body['scheduledFor'] = scheduledFor;
    }
    if (location != null && location.isNotEmpty) {
      body['location'] = location;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Moments.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Failed to create moment');
      }
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 
                          errorData['message'] ?? 
                          'Failed to create moment';
      throw Exception(errorMessage);
    }
  }

  Future<Moments> getSingleMoment({required String id}) async {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Moments.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Moment not found');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Moment not found');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to load moment');
    }
  }

  Future<Moments> updateMoment({
    required String id,
    required String title,
    required String description,
    String? category,
    String? mood,
    List<String>? tags,
    List<String>? images,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    // Build the request body
    final Map<String, dynamic> body = {
      'title': title.trim(),
      'description': description.trim(),
    };

    // Add optional fields only if they have values
    if (category != null && category.isNotEmpty) {
      body['category'] = category;
    }
    if (mood != null && mood.isNotEmpty) {
      body['mood'] = mood;
    }
    if (tags != null && tags.isNotEmpty) {
      // Enforce max 5 tags
      body['tags'] = tags.take(5).toList();
    }
    if (images != null) {
      // Send updated images array (filenames only)
      body['images'] = images;
    }

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Moments.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Failed to update moment');
      }
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 
                          errorData['message'] ?? 
                          'Failed to update moment';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> deleteUserMoment({required String id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.delete(
      Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return {
          "success": true,
          "data": data['data'] ?? {},
          "message": data['message'] ?? 'Moment deleted successfully',
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to delete moment');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Not authorized to delete this moment');
    } else if (response.statusCode == 404) {
      throw Exception('Moment not found');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to delete moment');
    }
  }

  Future<void> uploadMomentPhotos(
      String momentId, List<File> imageFiles) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images to upload');
    }

    // Enforce max 10 images per moment
    if (imageFiles.length > 10) {
      throw Exception('Maximum 10 images allowed per moment');
    }

    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/photo');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Validate and add files
    for (var imageFile in imageFiles) {
      // Check file size (10MB max)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image size exceeds 10MB limit: ${imageFile.path}');
      }

      // Determine content type from file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      String? mimeType;
      switch (extension) {
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
        default:
          throw Exception('Unsupported image format: $extension. Supported: JPEG, PNG, GIF, WEBP');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] != true) {
          throw Exception(responseData['error'] ?? 'Failed to upload images');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 
                       errorData['message'] ?? 
                       'Failed to upload images');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error uploading images: $e');
    }
  }

  Future<Map<String, dynamic>> likeMoment(String momentId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/like');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // No body required - user ID is taken from authentication token
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        return {
          'success': true,
          'likeCount': responseData['data']?['likeCount'] ?? 0,
          'isLiked': responseData['data']?['isLiked'] ?? true,
        };
      } else {
        throw Exception(responseData['error'] ?? 'Failed to like moment');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to like moment');
    }
  }

  Future<Map<String, dynamic>> dislikeMoment(String momentId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/dislike');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // No body required - user ID is taken from authentication token
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        return {
          'success': true,
          'likeCount': responseData['data']?['likeCount'] ?? 0,
          'isLiked': responseData['data']?['isLiked'] ?? false,
        };
      } else {
        throw Exception(responseData['error'] ?? 'Failed to dislike moment');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to dislike moment');
    }
  }
}

// Updated provider with family for pagination
final momentsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, page) async {
  final service = MomentsService();
  return service.getMoments(page: page, limit: 10);
});

/// Provider that returns a single, denormalized list of moments that can be
/// further filtered on the client (used by the new HelloTalk-style feed).
final momentsFeedProvider = FutureProvider<List<Moments>>((ref) async {
  final service = ref.watch(momentsServiceProvider);
  final response = await service.getMoments(page: 1, limit: 50);
  final moments = response['moments'];

  if (moments is List<Moments>) {
    return moments;
  }

  if (moments is List) {
    return moments.cast<Moments>();
  }

  return <Moments>[];
});

// Provider for user moments with family support
final userMomentsProvider = FutureProvider.family<List<Moments>, String>((ref, userId) async {
  final service = MomentsService();
  return service.getMomentsUser(id: userId, page: 1, limit: 50);
});

final momentsServiceProvider = Provider((ref) => MomentsService());
