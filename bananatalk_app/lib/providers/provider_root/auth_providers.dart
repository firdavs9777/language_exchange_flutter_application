import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class AuthService {
  bool isLoggedIn = false;
  String token = '';
  String userId = '';
  // String user_id = '';
  int count = 0;
  Future<bool> login({required String email, required String password}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.loginURL}');
    final response = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      userId = responseData['user']['_id'];
      print('UserId: $userId');
      token = responseData['token'];
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['token'].toString());
      isLoggedIn = true;

      return isLoggedIn;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<bool> logout() async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.logoutURL}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      userId = '';
      token = '';
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['token'].toString());
      isLoggedIn = false;
      return isLoggedIn;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Community> register(User user) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.registerURL}');
    final response = await http.post(
      url,
      body: jsonEncode(user),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Check for 201 Created status code
      isLoggedIn = true;
      final data = json.decode(response.body);
      token = data['token'];
      print(token);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', data['token'].toString());
      return Community.fromJson(data['user']);
      // return isLoggedIn;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> getLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String? token = prefs.getString('token');

    final url = Uri.parse('${Endpoints.baseURL}auth/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      String userId = data['data']['_id'];
      await prefs.setString('userId', userId);
      return Community.fromJson(data['data']);
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<void> uploadUserPhoto(String userId, List<File> imageFiles) async {
    print(userId);
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$userId/photo');
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
}

final authServiceProvider = Provider((ref) => AuthService());
final userProvider = FutureProvider<Community>((ref) async {
  return await ref.read(authServiceProvider).getLoggedInUser();
});
