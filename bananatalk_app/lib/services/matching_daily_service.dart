import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class MatchingDailyService {
  /// Never throws: 404 (kill switch), any non-200, or a network/parse error
  /// yields [DailyMatchesResult.unavailableResult].
  static Future<DailyMatchesResult> getDaily() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}matching/daily'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) return DailyMatchesResult.unavailableResult;
      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return DailyMatchesResult.unavailableResult;
      return DailyMatchesResult.fromJson(data);
    } catch (_) {
      return DailyMatchesResult.unavailableResult;
    }
  }
}
