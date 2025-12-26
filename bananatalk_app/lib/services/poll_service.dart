import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class PollService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new poll
  static Future<Map<String, dynamic>> createPoll({
    required String conversationId,
    required String receiverId,
    required String question,
    required List<String> options,
    PollSettings? settings,
    int? expiresInHours,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.createPollURL}');

      final body = {
        'conversation': conversationId,
        'receiver': receiverId,
        'question': question,
        'options': options.map((o) => {'text': o}).toList(),
        if (settings != null) 'settings': settings.toJson(),
        if (expiresInHours != null) 'expiresInHours': expiresInHours,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? Poll.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Poll created',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to create poll',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Vote on a poll
  static Future<Map<String, dynamic>> votePoll({
    required String pollId,
    required int optionIndex,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.votePollURL(pollId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'optionIndex': optionIndex}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? Poll.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Vote recorded',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to vote',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get poll details
  static Future<Map<String, dynamic>> getPoll({
    required String pollId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.getPollURL(pollId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? Poll.fromJson(data['data']) : null,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get poll',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Close a poll (only creator can close)
  static Future<Map<String, dynamic>> closePoll({
    required String pollId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.closePollURL(pollId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? Poll.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Poll closed',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to close poll',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

