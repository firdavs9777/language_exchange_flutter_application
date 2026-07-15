import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// One page of the Reels feed.
class ReelsPage {
  const ReelsPage({required this.reels, this.nextCursor});

  final List<Moments> reels;

  /// ISO-8601 `createdAt` cursor for the next page (`?before=`), or `null`
  /// when there's nothing more to load.
  final String? nextCursor;
}

/// Client for the Reels feed endpoint (Workstream G, Task 4).
///
/// API contract (backend track, built in parallel — see
/// `docs/superpowers/plans/2026-07-14-reels.md` Task 2):
/// `GET /api/v1/moments/reels?limit=&before=<ISO createdAt cursor>` ->
/// `{success, data: [moments], nextCursor}`. Reels are standard Moment JSON
/// (populated user/video/language/promptId/likeCount/commentCount/isLiked),
/// so this reuses the existing `Moments.fromJson` — no separate reel model.
/// The endpoint 404s when the server-side `REELS_ENABLED` kill switch is off.
class ReelsApiClient {
  Future<ReelsPage> getReels({String? before, int limit = 12}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var url = '${Endpoints.baseURL}${Endpoints.momentsURL}/reels?limit=$limit';
    if (before != null && before.isNotEmpty) {
      url += '&before=${Uri.encodeComponent(before)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['data'] as List<dynamic>? ?? const [])
            .map((m) => Moments.fromJson(m as Map<String, dynamic>))
            .toList();
        return ReelsPage(
          reels: list,
          nextCursor: data['nextCursor']?.toString(),
        );
      }
      throw Exception(data['error'] ?? 'Failed to load reels');
    }

    if (response.statusCode == 404) {
      // REELS_ENABLED kill switch is off server-side (or an old backend
      // that doesn't have the route yet).
      throw Exception('Reels are currently unavailable');
    }

    try {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['error'] ?? errorData['message'] ?? 'Failed to load reels',
      );
    } on FormatException {
      throw Exception('Failed to load reels');
    }
  }
}
