import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/providers/provider_models/comments_model.dart';

import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsService {
  Future<List<Comments>> getComments() async {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.commentUrl}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((postJson) => Comments.fromJson(postJson))
          .toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Comments> createComment({
    required String title,
    required String id,
    String? parentCommentId,
    String? imageUrl,
    Map<String, dynamic>? correction,
  }) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$id/${Endpoints.commentUrl}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final body = <String, dynamic>{'text': title};
    if (parentCommentId != null) {
      body['parentComment'] = parentCommentId;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      body['imageUrl'] = imageUrl;
    }
    if (correction != null) {
      body['correction'] = correction;
    }

    final response = await http.post(
      url,
      body: jsonEncode(body),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        // Backend may return user as ID or as populated object
        // Comments.fromJson will handle both cases
        return Comments.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Failed to create comment');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to create comment');
    }
  }

  Future<List<Comments>> getSingleComment({required String id}) async {
    final page = await getCommentsPage(id: id, page: 1, limit: 50);
    return page.comments;
  }

  /// Paginated comment fetch — backend `getComments` supports `page`/`limit`
  /// query params and returns `total`/`page`/`pages` alongside `data`. Used
  /// by [single_moment.dart]'s "Load more comments" button so long threads
  /// don't load in one shot.
  Future<CommentsPage> getCommentsPage({
    required String id,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(Uri.parse(
          '${Endpoints.baseURL}${Endpoints.momentsURL}/$id/${Endpoints.commentUrl}'
          '?page=$page&limit=$limit'));

      // Handle 500 errors from backend (backend issue with user population)
      if (response.statusCode == 500) {
        // Return empty page to prevent UI crash
        // The backend needs to fix the user population issue
        return CommentsPage.empty(page);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if response has error from backend
        if (data['success'] == false) {
          // If backend has an error but it's a data issue, try to return what we can
          if (data['data'] != null && data['data'] is List) {
            final commentsList = data['data'] as List;
            final comments = commentsList
                .map((commentJson) {
                  try {
                    if (commentJson is Map<String, dynamic>) {
                      return Comments.fromJson(commentJson);
                    }
                    return null;
                  } catch (e) {
                    return null;
                  }
                })
                .where((comment) => comment != null)
                .cast<Comments>()
                .toList();
            return CommentsPage(
              comments: comments,
              page: page,
              totalPages: 1,
              total: comments.length,
            );
          }
          return CommentsPage.empty(page);
        }

        // Handle case where data might be null or not a list
        if (data['data'] == null) {
          return CommentsPage.empty(page);
        }

        final commentsList = data['data'] is List ? data['data'] as List : [];

        final comments = commentsList
            .map((commentJson) {
              try {
                if (commentJson is! Map<String, dynamic>) {
                  return null;
                }
                return Comments.fromJson(commentJson);
              } catch (e) {
                // Skip invalid comments instead of crashing
                return null;
              }
            })
            .where((comment) => comment != null)
            .cast<Comments>()
            .toList();

        return CommentsPage(
          comments: comments,
          page: data['page'] is int ? data['page'] as int : page,
          totalPages: data['pages'] is int ? data['pages'] as int : 1,
          total: data['total'] is int ? data['total'] as int : comments.length,
        );
      } else {
        // Handle other HTTP errors — return empty page for non-critical errors
        return CommentsPage.empty(page);
      }
    } catch (e) {
      // Return empty page instead of throwing to prevent UI crashes
      return CommentsPage.empty(page);
    }
  }
}

/// Result of a single paginated comments fetch (top-level comments only —
/// mirrors the backend's `{data, total, page, pages}` shape for `getComments`).
class CommentsPage {
  const CommentsPage({
    required this.comments,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<Comments> comments;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  factory CommentsPage.empty(int page) => CommentsPage(
        comments: const [],
        page: page,
        totalPages: 1,
        total: 0,
      );
}

final commentsServiceProvider = Provider((ref) => CommentsService());

final commentsProvider =
    FutureProviderFamily<List<Comments>, String>((ref, postId) async {
  // Fetch comments and return List<Comments>
  final service = ref.read(commentsServiceProvider);
  return service.getSingleComment(id: postId); // Replace with your logic
});

/// Page size used by the paginated comments UI ("Load more comments").
const int kCommentsPageSize = 50;

/// Accumulating paginated comments state for a single moment. Starts with
/// page 1 (via [commentsProvider]'s same page size) and appends subsequent
/// pages on [loadMore]. Kept separate from [commentsProvider] so existing
/// consumers (e.g. `lib/pages/profile/moments/moment_card.dart`) that just
/// want "all comments so far" are unaffected.
class PaginatedComments {
  const PaginatedComments({
    this.comments = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.total = 0,
  });

  final List<Comments> comments;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Total top-level comment count reported by the backend for this moment
  /// (from `getComments`'s `total` field). Used to show a "N more" hint on
  /// the "Load more comments" button without any extra request.
  final int total;

  /// Remaining top-level comments not yet loaded, floored at 0.
  int get remaining => (total - comments.length).clamp(0, total);

  PaginatedComments copyWith({
    List<Comments>? comments,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    int? total,
  }) {
    return PaginatedComments(
      comments: comments ?? this.comments,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      total: total ?? this.total,
    );
  }
}

class PaginatedCommentsNotifier extends StateNotifier<AsyncValue<PaginatedComments>> {
  PaginatedCommentsNotifier(this._service, this._momentId)
      : super(const AsyncValue.loading()) {
    _loadFirstPage();
  }

  final CommentsService _service;
  final String _momentId;

  Future<void> _loadFirstPage() async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.getCommentsPage(
        id: _momentId,
        page: 1,
        limit: kCommentsPageSize,
      );
      state = AsyncValue.data(PaginatedComments(
        comments: result.comments,
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _loadFirstPage();

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await _service.getCommentsPage(
        id: _momentId,
        page: nextPage,
        limit: kCommentsPageSize,
      );
      state = AsyncValue.data(PaginatedComments(
        comments: [...current.comments, ...result.comments],
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
      ));
    } catch (e) {
      // Keep existing comments; just stop the loading spinner so the user
      // can retry via the button again.
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }
}

final paginatedCommentsProvider = StateNotifierProvider.family<
    PaginatedCommentsNotifier, AsyncValue<PaginatedComments>, String>(
  (ref, momentId) => PaginatedCommentsNotifier(
    ref.read(commentsServiceProvider),
    momentId,
  ),
);
