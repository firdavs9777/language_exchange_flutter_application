import 'dart:async';

import 'package:bananatalk_app/providers/hashtag_providers.dart';
import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/hashtag_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/moment_fixture.dart';

/// A load-more still in flight when the list is reloaded belongs to the old
/// list: it must not append to it, move the page counter, or let the next
/// load-more skip a page.
class _FakeService extends HashtagService {
  final pages = <int>[];
  final gates = <int, Completer<void>>{};

  @override
  Future<HashtagPage> moments(
    String tag, {
    String sort = 'top',
    int page = 1,
    int limit = 12,
  }) async {
    pages.add(page);
    final gate = gates.remove(page);
    if (gate != null) await gate.future;
    return HashtagPage(
      tag: tag,
      postCount: 99,
      moments: [buildMoment(id: '$tag-p$page-${pages.length}')],
      hasNextPage: true,
    );
  }
}

void main() {
  test('hashtag page: load-more across a reload does not skip a page',
      () async {
    final service = _FakeService();
    final c = ProviderContainer(
      overrides: [hashtagServiceProvider.overrideWithValue(service)],
    );
    addTearDown(c.dispose);
    final key = hashtagPageKey('korean')!;
    final p = hashtagPageProvider(key);
    c.listen(p, (_, __) {});
    await c.read(p.future);

    final slow = Completer<void>();
    final reload = Completer<void>();
    service.gates[2] = slow;
    final pending = c.read(p.notifier).loadMore();
    await Future<void>.delayed(Duration.zero);
    service.gates[1] = reload;
    c.invalidate(p);
    await Future<void>.delayed(Duration.zero);
    // The old page 2 lands while page 1 is being re-read.
    slow.complete();
    await pending;
    reload.complete();
    await c.read(p.future);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // The stale page 2 was not appended to the reloaded list.
    expect(c.read(p).value!.moments, hasLength(1));
    await c.read(p.notifier).loadMore();
    expect(service.pages, [1, 2, 1, 2]);
  });

  test('feed: load-more across a reload does not skip a page', () async {
    final pages = <int>[];
    final gates = <int, Completer<void>>{};
    final p = AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
      () => PagedMomentsFeedNotifier((ref, page) async {
        pages.add(page);
        final gate = gates.remove(page);
        if (gate != null) await gate.future;
        return MomentsFeedPage(
          [buildMoment(id: 'p$page-${pages.length}')],
          hasMore: true,
        );
      }),
    );
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final seen = <String>[];
    c.listen(p, (_, next) {
      for (final m in next.valueOrNull ?? <Moments>[]) {
        seen.add(m.id);
      }
    });
    await c.read(p.future);

    final slow = Completer<void>();
    final reload = Completer<void>();
    gates[2] = slow;
    final pending = c.read(p.notifier).loadMore();
    await Future<void>.delayed(Duration.zero);
    gates[1] = reload;
    c.invalidate(p);
    await Future<void>.delayed(Duration.zero);
    slow.complete();
    await pending;
    reload.complete();
    await c.read(p.future);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(c.read(p).value, hasLength(1));
    // The stale page was never shown, not even while page 1 was re-read.
    expect(seen.where((id) => id.startsWith('p2-')), isEmpty);
    await c.read(p.notifier).loadMore();
    expect(pages, [1, 2, 1, 2]);
  });
}
