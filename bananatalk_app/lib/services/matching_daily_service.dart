import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// A `matching/daily` failure the Matches tab should offer a retry for.
class MatchingDailyException implements Exception {
  const MatchingDailyException(this.message);
  final String message;

  @override
  String toString() => 'MatchingDailyException: $message';
}

class MatchingDailyService {
  /// 404 (kill switch) yields [DailyMatchesResult.unavailableResult] so the
  /// tab hides itself. Every other failure (network, 5xx, bad body) throws,
  /// so the tab shows its error state with Retry.
  static Future<DailyMatchesResult> getDaily() async {
    final response = await _request();
    return parseResponse(response.statusCode, response.body);
  }

  /// [getDaily] plus the decoded body as sent (null for the 404), for the
  /// first-page disk cache. Same request, same errors, one decode.
  static Future<({DailyMatchesResult result, Map<String, dynamic>? raw})>
      getDailyWithRaw() async {
    final response = await _request();
    return _parse(response.statusCode, response.body);
  }

  /// The one `GET matching/daily` both paths send.
  static Future<http.Response> _request() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return http.get(
      Uri.parse('${Endpoints.baseURL}matching/daily'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  @visibleForTesting
  static DailyMatchesResult parseResponse(int statusCode, String body) =>
      _parse(statusCode, body).result;

  static ({DailyMatchesResult result, Map<String, dynamic>? raw}) _parse(
    int statusCode,
    String body,
  ) {
    if (statusCode == 404) {
      return (result: DailyMatchesResult.unavailableResult, raw: null);
    }
    if (statusCode != 200) {
      throw MatchingDailyException('HTTP $statusCode');
    }
    final data = json.decode(body);
    if (data is! Map<String, dynamic>) {
      throw const MatchingDailyException('unexpected body');
    }
    return (result: DailyMatchesResult.fromJson(data), raw: data);
  }
}
