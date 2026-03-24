import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Authentication {
  static void regisiter() {
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:5001/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 404) {
    }

    if (response.statusCode == 200) {
      // Login successful, return response data
      return jsonDecode(response.body);
    } else {
      // Login failed, return error message
      return {'error': 'Login failed. Invalid email or password.'};
    }
  }
}
