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

  Future<Comments> createComment({required title, required id}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/${id}/${Endpoints.commentUrl}');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String? token = prefs.getString('token');
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
    print(response);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      return Comments.fromJson(
          data['data']); // Assuming 'data' is a map representing the new moment
    } else {
      throw Exception('Failed to create moment');
    }
  }

  Future<List<Comments>> getSingleComment({required String id}) async {
    try {
      print(id);
      final response = await http.get(Uri.parse(
          '${Endpoints.baseURL}${Endpoints.momentsURL}/$id/${Endpoints.commentUrl}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((commentJson) => Comments.fromJson(commentJson))
            .toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      throw Exception('Failed to get comment: $e');
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
