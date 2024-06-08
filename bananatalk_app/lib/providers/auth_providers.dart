import 'package:bananatalk_app/providers/models/users.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.loginURL}');
    final response = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> register(User user) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.registerURL}');
    final response = await http.post(
      url,
      body: jsonEncode(user.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }
}

final authServiceProvider = Provider((ref) => AuthService());
