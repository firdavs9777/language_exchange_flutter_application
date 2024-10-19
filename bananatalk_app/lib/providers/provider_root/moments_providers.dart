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
  Future<List<Moments>> getMoments() async {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return (data as List)
          .map((postJson) => Moments.fromJson(postJson))
          .toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<List<Moments>> getMomentsUser({required id}) async {
    final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/user/${id}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> momentsList =
          data['data']; // Assuming moments are in 'data' field
      count = data['count'];
      List<Moments> moments =
          momentsList.map((json) => Moments.fromJson(json)).toList();

      count = data['count'];
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('count', data['count'].toString());
      return moments;
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Moments> createMoments({required title, required description}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // print(userId);
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');
    print('Helloooooo $userId');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(
          {'title': title, 'description': description, 'user': userId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      return Moments.fromJson(
          data['data']); // Assuming 'data' is a map representing the new moment
    } else {
      throw Exception('Failed to create moment');
    }
  }

  Future<Moments> getSingleMoment({required id}) async {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/${id}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return Moments.fromJson(
          data['data']); // Assuming 'data' is a map representing the new moment
    } else {
      throw Exception('Failed to create moment');
    }
  }

  Future<void> uploadMomentPhotos(
      String momentId, List<File> imageFiles) async {
    print(momentId);
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/photo');
    final request = http.MultipartRequest('PUT', url);

    for (var imageFile in imageFiles) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }
    try {
      final response = await request.send();
      print(response);
      if (response.statusCode == 200) {
        print("Uploaded!");
      } else {
        print("Upload failed with status: ${response.statusCode}");
        response.stream.transform(utf8.decoder).listen((value) {
          print(value);
        });
      }
    } catch (e) {
      print("Error uploading file: $e");
    }
  }

  Future<void> likeMoment(String momentId, String userId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/${momentId}/like');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Moment liked successfully: $responseData');
    } else {
      final errorData = json.decode(response.body);
      print('Error liking moment: $errorData');
    }
  }

  Future<void> dislikeMoment(String momentId, String userId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/${momentId}/dislike');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Moment liked successfully: $responseData');
    } else {
      final errorData = json.decode(response.body);
      print('Error liking moment: $errorData');
    }
  }
}

final momentsProvider = FutureProvider<List<Moments>>((ref) async {
  final service = MomentsService();
  return service.getMoments();
});

final momentsServiceProvider = Provider((ref) => MomentsService());
