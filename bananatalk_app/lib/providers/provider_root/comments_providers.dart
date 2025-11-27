import 'dart:convert';
import 'package:bananatalk_app/providers/provider_models/comments_model.dart';

import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsService {
  Future<List<Comments>> getComments() async {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.commentUrl}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data['data']);
      return (data['data'] as List)
          .map((postJson) => Comments.fromJson(postJson))
          .toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Comments> createComment({required String title, required String id}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$id/${Endpoints.commentUrl}');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.post(
      url,
      body: jsonEncode({
        'text': title,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        // Backend may return user as ID or as populated object
        // Comments.fromJson will handle both cases
        return Comments.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Failed to create comment');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to create comment');
    }
  }

  Future<List<Comments>> getSingleComment({required String id}) async {
    try {
      final response = await http.get(Uri.parse(
          '${Endpoints.baseURL}${Endpoints.momentsURL}/$id/${Endpoints.commentUrl}'));
      
      // Handle 500 errors from backend (backend issue with user population)
      if (response.statusCode == 500) {
        print('Backend 500 error - likely user population issue');
        // Return empty list to prevent UI crash
        // The backend needs to fix the user population issue
        return [];
      }
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if response has error from backend
        if (data['success'] == false) {
          final errorMsg = data['error'] ?? 'Failed to load comments';
          print('Backend error loading comments: $errorMsg');
          
          // If backend has an error but it's a data issue, try to return what we can
          if (data['data'] != null && data['data'] is List) {
            final commentsList = data['data'] as List;
            return commentsList
                .map((commentJson) {
                  try {
                    if (commentJson is Map<String, dynamic>) {
                      return Comments.fromJson(commentJson);
                    }
                    return null;
                  } catch (e) {
                    print('Error parsing comment: $e');
                    return null;
                  }
                })
                .where((comment) => comment != null)
                .cast<Comments>()
                .toList();
          }
          return [];
        }
        
        // Handle case where data might be null or not a list
        if (data['data'] == null) {
          return [];
        }
        
        final commentsList = data['data'] is List ? data['data'] as List : [];
        
        if (commentsList.isEmpty) {
          return [];
        }
        
        return commentsList
            .map((commentJson) {
              try {
                if (commentJson is! Map<String, dynamic>) {
                  print('Invalid comment format: $commentJson');
                  return null;
                }
                return Comments.fromJson(commentJson);
              } catch (e) {
                print('Error parsing comment: $e, commentJson: $commentJson');
                // Skip invalid comments instead of crashing
                return null;
              }
            })
            .where((comment) => comment != null)
            .cast<Comments>()
            .toList();
      } else {
        // Handle other HTTP errors
        try {
          final errorData = json.decode(response.body);
          final errorMsg = errorData['error'] ?? 
                          errorData['message'] ?? 
                          'Failed to load comments';
          print('HTTP error ${response.statusCode}: $errorMsg');
        } catch (_) {
          print('HTTP error ${response.statusCode}: ${response.body}');
        }
        // Return empty list for non-critical errors
        return [];
      }
    } catch (e) {
      print('Error in getSingleComment: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }
}

final commentsServiceProvider = Provider((ref) => CommentsService());

final commentsProvider =
    FutureProviderFamily<List<Comments>, String>((ref, postId) async {
  // Fetch comments and return List<Comments>
  final service = ref.read(commentsServiceProvider);
  return service.getSingleComment(id: postId); // Replace with your logic
});
