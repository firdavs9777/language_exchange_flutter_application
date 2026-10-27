import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/provider_models/comments_model.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';

/// The thread used to collapse to a spinner on every 15 s poll and after
/// each like (refresh set AsyncLoading with no previous value), dropped the
/// pages loaded with "Load more", and showed "No comments yet" when loading
/// failed.
class _FakeService extends CommentsService {
  _FakeService(this.total);

  final int total;
  bool fail = false;
  final limits = <int>[];

  @override
  Future<CommentsPage> getCommentsPage({
    required String id,
    int page = 1,
    int limit = 50,
  }) async {
    limits.add(limit);
    if (fail) throw Exception('offline');
    final start = (page - 1) * limit;
    final count = (total - start).clamp(0, limit);
    return CommentsPage(
      comments: [
        for (var i = 0; i < count; i++)
          Comments.fromJson({'_id': 'c${start + i}', 'text': 't', 'user': 'u'}),
      ],
      page: page,
      totalPages: (total / limit).ceil(),
      total: total,
    );
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a failed first load is an error, not an empty thread', () async {
    final service = _FakeService(3)..fail = true;
    final notifier = PaginatedCommentsNotifier(service, 'm1');
    await _settle();
    expect(notifier.state, isA<AsyncError<PaginatedComments>>());
  });

  test('refresh keeps the thread on screen and the loaded pages', () async {
    final service = _FakeService(120);
    final notifier = PaginatedCommentsNotifier(service, 'm1');
    await _settle();
    await notifier.loadMore();
    expect(notifier.state.value!.comments, hasLength(100));

    final states = <bool>[];
    notifier.addListener((s) => states.add(s.isLoading), fireImmediately: false);
    await notifier.refresh();

    expect(states.where((loading) => loading), isEmpty,
        reason: 'refresh must not flash a spinner');
    expect(service.limits.last, 100, reason: 'reloads what was loaded');
    expect(notifier.state.value!.comments, hasLength(100));
    expect(notifier.state.value!.hasMore, isTrue);

    await notifier.loadMore();
    expect(notifier.state.value!.comments, hasLength(120));
  });

  test('a failed refresh keeps what is shown', () async {
    final service = _FakeService(3);
    final notifier = PaginatedCommentsNotifier(service, 'm1');
    await _settle();
    service.fail = true;
    await notifier.refresh();
    expect(notifier.state.value!.comments, hasLength(3));
  });

  test('a failed Load more keeps the button (hasMore stays true)', () async {
    final service = _FakeService(80);
    final notifier = PaginatedCommentsNotifier(service, 'm1');
    await _settle();
    service.fail = true;
    await notifier.loadMore();
    expect(notifier.state.value!.comments, hasLength(50));
    expect(notifier.state.value!.hasMore, isTrue);
  });
}
