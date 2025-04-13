import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:flutter/cupertino.dart';
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
      token = responseData['token'];
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['token'].toString());
      prefs.setString('userId', responseData['user']['_id'].toString());
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
      await prefs.remove('token');
      await prefs.remove('userId');
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
      final prefs = await SharedPreferences.getInstance();
      // Check for 201 Created status code
      isLoggedIn = true;
      final data = jsonDecode(response.body);
      token = data['token'];
      prefs.setString('token', data['token'].toString());
      prefs.setString('userId', data['user']['_id'].toString());
      return Community.fromJson(data['user']);
      // return isLoggedIn;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> getLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String

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
      throw Exception('Failed to load user info');
    }
  }

  Future<String> sendEmailCode({required email}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.sendCode}');
    final response = await http.post(url, body: {'email': email});
    if (response.statusCode == 200) {
      return 'Verification code sent';
    } else {
      throw Exception('Failed to find user email');
    }
  }

  Future<String> verifyEmailCode({required email, required code}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.verifyEmailCode}');
    final response = await http.post(url, body: {'email': email, 'code': code});
    if (response.statusCode == 200) {
      return 'Verification code successully verified';
    } else {
      throw Exception('Failed to verify email, please try one more time');
    }
  }

  Future<String> resetPassword({required email, required newPassword}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.resetPassword}');
    final response = await http
        .post(url, body: {'email': email, 'newPassword': newPassword});
    if (response.statusCode == 200) {
      return 'Password reset successfully';
    } else {
      throw Exception('Failed to reset password, please try one more time');
    }
  }

  Future<Community> updateUserMbti({required mbti}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'mbti': mbti}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['data']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserBloodType({required bloodType}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'bloodType': bloodType}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['data']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserName({required userName, required gender}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'name': userName, 'gender': gender}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['data']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<List<Community>> getFollowersUser({required id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && token.isEmpty) {
      throw Exception('There is no token, please check');
    }

    final url = Uri.parse('${Endpoints.baseURL}auth/users/$id/followers');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> followersList = data['followers'];
      List<Community> followers =
          followersList.map((json) => Community.fromJson(json)).toList();

      return followers;
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<List<Community>> getFollowingsUser({required id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && token.isEmpty) {
      throw Exception('There is no token, please check');
    }

    final url = Uri.parse('${Endpoints.baseURL}auth/users/$id/following');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> followersList = data['following'];
      List<Community> followings =
          followersList.map((json) => Community.fromJson(json)).toList();

      return followings;
    } else {
      throw Exception('Failed to load ');
    }
  }

  Future<void> uploadUserPhoto(String userId, List<File> imageFiles) async {
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
      if (response.statusCode == 200) {
      } else {
        response.stream.transform(utf8.decoder).listen((value) {});
      }
    } catch (e) {}
  }
}

final authServiceProvider = Provider((ref) => AuthService());
final userProvider = FutureProvider<Community>((ref) async {
  try {
    return await ref.read(authServiceProvider).getLoggedInUser();
  } catch (e) {
    debugPrint('Error fetching user: $e');
    throw Exception('Unable to fetch user');
  }
});
