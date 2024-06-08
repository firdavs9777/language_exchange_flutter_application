import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Authentication {
  static void regisiter() {
    print('Register');
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:5001/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 404) {
      print(response);
    }

    if (response.statusCode == 200) {
      // Login successful, return response data
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } else {
      print('error coccured');
      // Login failed, return error message
      return {'error': 'Login failed. Invalid email or password.'};
    }
  }
}
