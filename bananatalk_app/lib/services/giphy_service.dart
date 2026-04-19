import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// MODEL
// ============================================================================

/// Represents a single GIF returned from the GIPHY API.
class GiphyGif {
  final String id;
  final String title;

  /// URL for the fixed_width_small rendition — used in the grid preview.
  final String previewUrl;

  /// URL for the original rendition — sent as the chat message payload.
  final String originalUrl;

  /// Original width in pixels (may be 0 if not provided by GIPHY).
  final int width;

  /// Original height in pixels (may be 0 if not provided by GIPHY).
  final int height;

  const GiphyGif({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
    required this.width,
    required this.height,
  });

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>? ?? {};

    final fixedWidthSmall =
        images['fixed_width_small'] as Map<String, dynamic>? ?? {};
    final original = images['original'] as Map<String, dynamic>? ?? {};

    final previewUrl = (fixedWidthSmall['url'] as String? ?? '').split('?').first;
    final originalUrl = (original['url'] as String? ?? '').split('?').first;

    final widthStr = original['width'] as String? ?? '0';
    final heightStr = original['height'] as String? ?? '0';

    return GiphyGif(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      previewUrl: previewUrl,
      originalUrl: originalUrl,
      width: int.tryParse(widthStr) ?? 0,
      height: int.tryParse(heightStr) ?? 0,
    );
  }

  /// Returns the aspect ratio (width / height). Falls back to 1.0 if either
  /// dimension is unknown so the grid cell still renders cleanly.
  double get aspectRatio =>
      (width > 0 && height > 0) ? width / height : 1.0;

  @override
  String toString() => 'GiphyGif(id: $id, title: $title)';
}

// ============================================================================
// SERVICE
// ============================================================================

class GiphyService {
  static const String _baseUrl = 'https://api.giphy.com/v1/gifs';

  String get _apiKey => dotenv.env['GIPHY_API_KEY'] ?? '';

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Searches GIPHY for GIFs matching [query].
  ///
  /// [limit] max results per page (1-50, default 25).
  /// [offset] pagination offset (default 0).
  Future<List<GiphyGif>> searchGifs(
    String query, {
    int limit = 25,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) return getTrendingGifs(limit: limit, offset: offset);

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'api_key': _apiKey,
      'q': query.trim(),
      'limit': limit.toString(),
      'offset': offset.toString(),
      'rating': 'g',
      'lang': 'en',
    });

    return _fetchGifs(uri);
  }

  /// Fetches GIPHY trending GIFs.
  ///
  /// [limit] max results per page (1-50, default 25).
  /// [offset] pagination offset (default 0).
  Future<List<GiphyGif>> getTrendingGifs({
    int limit = 25,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/trending').replace(queryParameters: {
      'api_key': _apiKey,
      'limit': limit.toString(),
      'offset': offset.toString(),
      'rating': 'g',
    });

    return _fetchGifs(uri);
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<List<GiphyGif>> _fetchGifs(Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        return data
            .whereType<Map<String, dynamic>>()
            .map(GiphyGif.fromJson)
            .where((gif) => gif.previewUrl.isNotEmpty && gif.originalUrl.isNotEmpty)
            .toList();
      } else {
        throw GiphyException(
          'GIPHY API error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on GiphyException {
      rethrow;
    } catch (e) {
      throw GiphyException('Network error: $e');
    }
  }
}

// ============================================================================
// EXCEPTION
// ============================================================================

class GiphyException implements Exception {
  final String message;
  final int? statusCode;

  const GiphyException(this.message, {this.statusCode});

  @override
  String toString() => 'GiphyException($message)';
}

// ============================================================================
// RIVERPOD PROVIDER
// ============================================================================

final giphyServiceProvider = Provider<GiphyService>((ref) => GiphyService());
