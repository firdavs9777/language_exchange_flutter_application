import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/reels_api_client.dart';

/// Paginated state shared by the Reels grid landing and the full-screen
/// swipe feed (Workstream G, Tasks 4-5) — both read the same list + cursor
/// so tapping a grid tile opens the swipe feed already showing the same
/// data, no separate fetch.
class ReelsFeedState {
  const ReelsFeedState({
    this.reels = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Moments> reels;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  ReelsFeedState copyWith({
    List<Moments>? reels,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ReelsFeedState(
      reels: reels ?? this.reels,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReelsFeedNotifier extends StateNotifier<ReelsFeedState> {
  ReelsFeedNotifier(this._client) : super(const ReelsFeedState()) {
    refresh();
  }

  final ReelsApiClient _client;
  static const int _pageSize = 12;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _client.getReels(limit: _pageSize);
      state = ReelsFeedState(
        reels: page.reels,
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _client.getReels(
        before: state.nextCursor,
        limit: _pageSize,
      );
      state = state.copyWith(
        reels: [...state.reels, ...page.reels],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  /// Replaces a single reel in-place (e.g. after a like toggle) so the grid
  /// and swipe feed stay in sync without a full refetch.
  void updateReel(Moments updated) {
    state = state.copyWith(
      reels: [
        for (final r in state.reels)
          if (r.id == updated.id) updated else r,
      ],
    );
  }
}

final reelsApiClientProvider = Provider<ReelsApiClient>((ref) {
  return ReelsApiClient();
});

final reelsFeedProvider =
    StateNotifierProvider<ReelsFeedNotifier, ReelsFeedState>((ref) {
  return ReelsFeedNotifier(ref.watch(reelsApiClientProvider));
});
