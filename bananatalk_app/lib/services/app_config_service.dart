import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class AppConfigService {
  static const Duration _timeout = Duration(seconds: 5);

  Future<AppConfig?> fetch() async {
    try {
      final res = await http
          .get(Uri.parse('${Endpoints.baseURL}${Endpoints.appConfigURL}'))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;

      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;

      return AppConfig.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('AppConfigService.fetch failed: $e');
      return null;
    }
  }
}
