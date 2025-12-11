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
      'Accept': 'application/json',
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
          '${Endpoints.baseURL}${Endpoints.getVipStatusURL(userId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final vipData = data['data'];
          return {
            'success': true,
            'data': vipData,
            'isVIP': vipData['isVIP'] ?? false,
            'userMode': vipData['userMode'] ?? 'regular',
            'vipSubscription': vipData['vipSubscription'] != null
                ? VipSubscription.fromJson(vipData['vipSubscription'])
                : null,
            'vipFeatures': vipData['vipFeatures'] != null
                ? VipFeatures.fromJson(vipData['vipFeatures'])
                : null,
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'Failed to get VIP status',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? errorData['message'] ?? 'Failed to get VIP status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify iOS purchase receipt
  static Future<Map<String, dynamic>> verifyIOSPurchase({
    required String receiptData,
    String? productId,
    String? transactionId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.iosVerifyPurchaseURL}');

      final requestBody = <String, dynamic>{
        'receiptData': receiptData,
      };
      
      if (productId != null) {
        requestBody['productId'] = productId;
      }
      
      if (transactionId != null) {
        requestBody['transactionId'] = transactionId;
      }

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'VIP subscription activated successfully',
            'data': data['data'],
            'plan': data['data']?['plan'],
            'isActive': data['data']?['isActive'] ?? true,
            'endDate': data['data']?['endDate'] != null
                ? DateTime.parse(data['data']['endDate'])
                : null,
            'nextBillingDate': data['data']?['nextBillingDate'] != null
                ? DateTime.parse(data['data']['nextBillingDate'])
                : null,
            'userMode': data['data']?['userMode'] ?? 'vip',
            'vipFeatures': data['data']?['vipFeatures'] != null
                ? VipFeatures.fromJson(data['data']['vipFeatures'])
                : null,
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? data['message'] ?? 'Purchase verification failed',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? errorData['message'] ?? 'Purchase verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Check iOS subscription status
  static Future<Map<String, dynamic>> checkIOSSubscriptionStatus({
    required String receiptData,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.iosSubscriptionStatusURL}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'receiptData': receiptData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final statusData = data['data'];
          return {
            'success': true,
            'data': statusData,
            'isActive': statusData['isActive'] ?? false,
            'expiresDate': statusData['expiresDate'] != null
                ? DateTime.parse(statusData['expiresDate'])
                : null,
            'productId': statusData['productId'],
            'userVIPStatus': statusData['userVIPStatus'],
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'Failed to check subscription status',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? errorData['message'] ?? 'Failed to check subscription status',
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
