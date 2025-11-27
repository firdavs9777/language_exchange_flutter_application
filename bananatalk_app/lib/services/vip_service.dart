import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VipService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Activate VIP subscription
  static Future<Map<String, dynamic>> activateVip({
    required String userId,
    required VipPlan plan,
    required String paymentMethod,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/vip/activate');

      print('VIP Activate URL: $url');
      print('VIP Activate Request: plan=${plan.toJson()}, payment=$paymentMethod');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'plan': plan.toJson(),
          'paymentMethod': paymentMethod,
        }),
      );

      print('VIP Activate Response Status: ${response.statusCode}');
      print('VIP Activate Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'data': data,
          };
        } catch (e) {
          print('JSON Parse Error: $e');
          return {
            'success': false,
            'error': 'Invalid response format from server',
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['message'] ?? 'Failed to activate VIP subscription',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Server error: ${response.statusCode} - ${response.body}',
          };
        }
      }
    } catch (e) {
      print('VIP Activate Error: $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Deactivate VIP subscription
  static Future<Map<String, dynamic>> deactivateVip({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/vip/deactivate');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Failed to deactivate VIP subscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get VIP status
  static Future<Map<String, dynamic>> getVipStatus({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/vip/status');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'vipSubscription': data['vipSubscription'] != null
              ? VipSubscription.fromJson(data['vipSubscription'])
              : null,
          'vipFeatures': data['vipFeatures'] != null
              ? VipFeatures.fromJson(data['vipFeatures'])
              : null,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Failed to get VIP status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Upgrade visitor to regular user
  static Future<Map<String, dynamic>> upgradeVisitor({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/upgrade-visitor');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Failed to upgrade visitor account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get visitor limits
  static Future<Map<String, dynamic>> getVisitorLimits({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/visitor/limits');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'visitorLimitations': data['limitations'] != null
              ? VisitorLimitations.fromJson(data['limitations'])
              : null,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Failed to get visitor limits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Change user mode (admin only)
  static Future<Map<String, dynamic>> changeUserMode({
    required String userId,
    required UserMode newMode,
  }) async {
    try {
      final token = await _getToken();
      final url =
          Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$userId/mode');

      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'mode': newMode.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Failed to change user mode',
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
