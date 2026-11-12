import 'dart:convert';

import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Hashtag endpoints: suggestions, trending and a hashtag's moments.
///
/// All three answer 404 while the server switch is off; that reads as
/// "nothing" (empty list / empty page). Any other non-2xx throws.
class HashtagService {
  HashtagService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// The decoded body, or null for a 404.
  Future<Map<String, dynamic>?> _get(Uri uri) async {
    final response = await _client.get(uri, headers: await _headers());
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Hashtag request failed (${response.statusCode})');
    }
    final body = json.decode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected hashtag response');
    }
    return body;
  }

  static List<HashtagCount> _counts(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! List) return const [];
    return [
      for (final item in data)
        if (HashtagCount.tryParse(item) case final c?) c,
    ];
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${Endpoints.baseURL}$path').replace(queryParameters: query);

  Future<List<HashtagCount>> suggest(String q) async =>
      _counts(await _get(_uri(Endpoints.hashtagSuggestURL, {'q': q})));

  Future<List<HashtagCount>> trending() async =>
      _counts(await _get(_uri(Endpoints.hashtagTrendingURL)));

  Future<HashtagPage> moments(
    String tag, {
    String sort = 'top',
    int page = 1,
    int limit = 12,
  }) async {
    final body = await _get(
      _uri(Endpoints.hashtagMomentsURL(tag), {
        'sort': sort,
        'page': '$page',
        'limit': '$limit',
      }),
    );
    if (body == null) return HashtagPage.empty(tag);

    final data = body['data'];
    final moments = <Moments>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        try {
          moments.add(Moments.fromJson(item));
        } catch (_) {
          // One bad item must not lose the page.
        }
      }
    }
    final pagination = body['pagination'];
    var hasNext = false;
    if (pagination is Map) {
      final current = pagination['currentPage'];
      final total = pagination['totalPages'];
      hasNext = current is num && total is num && current < total;
    }
    final serverTag = body['tag'];
    final postCount = body['postCount'];
    final related = body['relatedTopic'];
    return HashtagPage(
      tag: serverTag is String && serverTag.isNotEmpty ? serverTag : tag,
      postCount: postCount is num ? postCount.toInt() : 0,
      relatedTopic: related is String && related.isNotEmpty ? related : null,
      moments: moments,
      hasNextPage: hasNext,
    );
  }
}
