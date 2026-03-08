// lib/utils/pagination_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic paginated response
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pages;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
    required this.hasMore,
  });

  factory PaginatedResponse.empty() => PaginatedResponse<T>(
        items: [],
        total: 0,
        page: 1,
        pages: 1,
        hasMore: false,
      );
}

/// Generic pagination state
class PaginationState<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DateTime? lastRefresh;

  const PaginationState({
    this.items = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastRefresh,
  });

  bool get isEmpty => items.isEmpty && !isLoading;
  bool get hasError => error != null;
  bool get canLoadMore => hasMore && !isLoadingMore && !isLoading;

  PaginationState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    DateTime? lastRefresh,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  /// Create initial loading state
  PaginationState<T> startLoading() => copyWith(
        isLoading: true,
        error: null,
      );

  /// Create loading more state
  PaginationState<T> startLoadingMore() => copyWith(
        isLoadingMore: true,
        error: null,
      );

  /// Create success state with items
  PaginationState<T> success({
    required List<T> items,
    required int page,
    required int pages,
    required int total,
    required bool hasMore,
    bool append = false,
  }) =>
      copyWith(
        items: append ? [...this.items, ...items] : items,
        currentPage: page,
        totalPages: pages,
        total: total,
        hasMore: hasMore,
        isLoading: false,
        isLoadingMore: false,
        lastRefresh: DateTime.now(),
      );

  /// Create error state
  PaginationState<T> failure(String message) => copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: message,
      );
}

/// Generic pagination notifier
abstract class PaginationNotifier<T> extends StateNotifier<PaginationState<T>> {
  final int pageSize;

  PaginationNotifier({this.pageSize = 20}) : super(const PaginationState());

  /// Fetch data from API - implement this in subclass
  Future<PaginatedResponse<T>> fetchPage(int page, int limit);

  /// Optional: Sort items after fetching
  List<T> sortItems(List<T> items) => items;

  /// Optional: Filter items
  List<T> filterItems(List<T> items) => items;

  /// Load initial data
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.startLoading();

    try {
      final response = await fetchPage(1, pageSize);
      final sorted = sortItems(response.items);
      final filtered = filterItems(sorted);

      state = state.success(
        items: filtered,
        page: 1,
        pages: response.pages,
        total: response.total,
        hasMore: response.hasMore,
      );
    } catch (e) {
      state = state.failure(e.toString());
    }
  }

  /// Load more data
  Future<void> loadMore() async {
    if (!state.canLoadMore) return;

    state = state.startLoadingMore();

    try {
      final nextPage = state.currentPage + 1;
      final response = await fetchPage(nextPage, pageSize);
      final sorted = sortItems(response.items);
      final filtered = filterItems(sorted);

      state = state.success(
        items: filtered,
        page: nextPage,
        pages: response.pages,
        total: response.total,
        hasMore: response.hasMore,
        append: true,
      );
    } catch (e) {
      state = state.failure(e.toString());
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    state = const PaginationState();
    await loadInitial();
  }

  /// Update a single item in the list
  void updateItem(bool Function(T) predicate, T Function(T) updater) {
    final index = state.items.indexWhere(predicate);
    if (index != -1) {
      final newItems = List<T>.from(state.items);
      newItems[index] = updater(newItems[index]);
      state = state.copyWith(items: newItems);
    }
  }

  /// Remove an item from the list
  void removeItem(bool Function(T) predicate) {
    final newItems = state.items.where((item) => !predicate(item)).toList();
    state = state.copyWith(
      items: newItems,
      total: state.total - 1,
    );
  }

  /// Add an item to the beginning of the list
  void prependItem(T item) {
    state = state.copyWith(
      items: [item, ...state.items],
      total: state.total + 1,
    );
  }
}

/// Mixin for scroll-based pagination
mixin PaginationScrollMixin<T extends StatefulWidget> on State<T> {
  ScrollController get scrollController;
  VoidCallback get onLoadMore;

  double get loadMoreThreshold => 0.8; // Load more at 80% scroll

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    final threshold = maxScroll * loadMoreThreshold;

    if (currentScroll >= threshold) {
      onLoadMore();
    }
  }
}

/// Widget that triggers load more when scrolled near bottom
class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback? onRefresh;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? loadingMoreWidget;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final double loadMoreThreshold;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    this.onRefresh,
    this.emptyWidget,
    this.loadingWidget,
    this.loadingMoreWidget,
    this.controller,
    this.padding,
    this.loadMoreThreshold = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? const Center(child: Text('No items'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final maxScroll = notification.metrics.maxScrollExtent;
          final currentScroll = notification.metrics.pixels;
          final threshold = maxScroll * loadMoreThreshold;

          if (currentScroll >= threshold && hasMore && !isLoadingMore) {
            onLoadMore();
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async => onRefresh?.call(),
        child: ListView.builder(
          controller: controller,
          padding: padding,
          itemCount: items.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return loadingMoreWidget ??
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
            }
            return itemBuilder(context, items[index], index);
          },
        ),
      ),
    );
  }
}
