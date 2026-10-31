import 'dart:async';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Partners list notifier (audit 2026-10-30): pull-to-refresh wiped the list
/// to a skeleton and, during a page-2 load, ended with page 2 stapled onto
/// the new page 1; hasMore was guessed from `pages`.
Community _u(String id) => Community.fromJson({
  '_id': id,
  'name': id,
  'native_language': 'Korean',
  'language_to_learn': 'English',
  'location': {'type': 'Point', 'coordinates': [0, 0], 'city': '', 'country': ''},
});

PaginatedCommunityResponse _page(List<String> ids, {bool hasMore = true}) =>
    PaginatedCommunityResponse(
      users: ids.map(_u).toList(),
      total: 100,
      page: 1,
      pages: 5,
      hasMore: hasMore,
    );

class _FakeService extends CommunityService {
  final calls = <Completer<PaginatedCommunityResponse>>[];
  final pages = <int>[];

  @override
  Future<PaginatedCommunityResponse> getUsersPage(Map<String, String> query) {
    final c = Completer<PaginatedCommunityResponse>();
    calls.add(c);
    pages.add(int.parse(query['page']!));
    return c.future;
  }
}

void main() {
  const a = PartnerFilterParams(gender: 'female');
  const b = PartnerFilterParams(gender: 'male');

  Future<(_FakeService, PartnerFilterNotifier)> loaded() async {
    final service = _FakeService();
    final n = PartnerFilterNotifier(service, () => false);
    final f = n.loadWithFilters(a);
    service.calls.last.complete(_page(['p1a', 'p1b']));
    await f;
    return (service, n);
  }

  test('refresh keeps the rows until page 1 arrives', () async {
    final (service, n) = await loaded();
    final r = n.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(n.state.users.map((u) => u.id), ['p1a', 'p1b']);
    service.calls.last.complete(_page(['new1']));
    await r;
    expect(n.state.users.map((u) => u.id), ['new1']);
  });

  test('refresh during loadMore drops the stale page 2', () async {
    final (service, n) = await loaded();
    final more = n.loadMore();
    final moreCall = service.calls.last;
    final r = n.refresh();
    final refreshCall = service.calls.last;
    // The fresh page 1 lands first; the old page 2 must not be appended.
    refreshCall.complete(_page(['new1']));
    await r;
    moreCall.complete(_page(['p2a']));
    await more;
    expect(n.state.users.map((u) => u.id), ['new1']);
  });

  test('a response for old filters is dropped', () async {
    final service = _FakeService();
    final n = PartnerFilterNotifier(service, () => false);
    final fa = n.loadWithFilters(a);
    final callA = service.calls.last;
    final fb = n.loadWithFilters(b);
    service.calls.last.complete(_page(['b1']));
    await fb;
    callA.complete(_page(['a1']));
    await fa;
    expect(n.state.users.map((u) => u.id), ['b1']);
  });

  test('loadMore lists a repeated person once', () async {
    final (service, n) = await loaded();
    final more = n.loadMore();
    service.calls.last.complete(_page(['p1a', 'p2a']));
    await more;
    expect(n.state.users.map((u) => u.id), ['p1a', 'p1b', 'p2a']);
  });

  test('hasMore comes from the server when it answers it', () {
    final r = PaginatedCommunityResponse.fromBody(
      {'data': [], 'total': 100, 'pages': 5, 'hasMore': false},
      page: 1,
    );
    expect(r.hasMore, isFalse);
    final old = PaginatedCommunityResponse.fromBody(
      {'data': [], 'total': 100, 'pages': 5},
      page: 1,
    );
    expect(old.hasMore, isTrue);
  });
}
