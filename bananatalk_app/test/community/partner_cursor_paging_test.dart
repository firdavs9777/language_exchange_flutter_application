import 'dart:async';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slim rows and cursor paging for the Partners list (Plan C2, Task 3).
/// Both are behind the server's fast-list flag; with it off every request is
/// exactly what shipped before.
Community _u(String id) => Community.fromJson({
  '_id': id,
  'name': id,
  'native_language': 'Korean',
  'language_to_learn': 'English',
  'location': {'type': 'Point', 'coordinates': [0, 0], 'city': '', 'country': ''},
});

PaginatedCommunityResponse _page(
  List<String> ids, {
  bool hasMore = true,
  String? cursor,
}) => PaginatedCommunityResponse(
  users: ids.map(_u).toList(),
  total: 100,
  page: 1,
  pages: 5,
  hasMore: hasMore,
  nextCursor: cursor,
);

class _FakeService extends CommunityService {
  final queries = <Map<String, String>>[];
  final calls = <Completer<PaginatedCommunityResponse>>[];

  @override
  Future<PaginatedCommunityResponse> getUsersPage(Map<String, String> query) {
    queries.add(query);
    final c = Completer<PaginatedCommunityResponse>();
    calls.add(c);
    return c.future;
  }

  void answer(PaginatedCommunityResponse r) => calls.last.complete(r);
  void fail() => calls.last.completeError(Exception('offline'));
}

void main() {
  const a = PartnerFilterParams(gender: 'female');
  const b = PartnerFilterParams(gender: 'male');

  late _FakeService service;
  late PartnerFilterNotifier n;

  void build({required bool fast}) {
    service = _FakeService();
    n = PartnerFilterNotifier(service, () => false, () => fast);
  }

  Future<void> page1(
    List<String> ids, {
    String? cursor,
    bool hasMore = true,
    PartnerFilterParams filters = a,
  }) async {
    final f = n.loadWithFilters(filters);
    service.answer(_page(ids, cursor: cursor, hasMore: hasMore));
    await f;
  }

  Future<void> more(
    List<String> ids, {
    String? cursor,
    bool hasMore = true,
  }) async {
    final f = n.loadMore(force: true);
    service.answer(_page(ids, cursor: cursor, hasMore: hasMore));
    await f;
  }

  group('flag off', () {
    setUp(() => build(fast: false));

    test('page 1 and page 2 queries are exactly today\'s', () async {
      await page1(['x1'], cursor: 'C1');
      await more(['x2']);
      const golden = {'limit': '20', 'matchLanguage': 'true', 'gender': 'female'};
      expect(service.queries[0], {...golden, 'page': '1'});
      expect(service.queries[1], {...golden, 'page': '2'});
    });

    test('a nextCursor in the response is ignored and never stored', () async {
      await page1(['x1'], cursor: 'C1');
      expect(n.state.nextCursor, isNull);
      await more(['x2'], cursor: 'C2');
      expect(n.state.nextCursor, isNull);
      await more(['x3']);
      expect(service.queries[2].containsKey('cursor'), isFalse);
    });

    test('hasMore keeps today\'s rule: an empty page ends the list', () async {
      await page1(['x1'], cursor: 'C1');
      await more([], cursor: 'C2');
      expect(n.state.hasMore, isFalse);
    });
  });

  group('flag on', () {
    setUp(() => build(fast: true));

    test('slim=1 on page 1 and page 2', () async {
      await page1(['x1']);
      await more(['x2']);
      expect(service.queries[0]['slim'], '1');
      expect(service.queries[1]['slim'], '1');
    });

    test('page 2 sends the cursor together with page=2', () async {
      await page1(['x1'], cursor: 'C1');
      expect(n.state.nextCursor, 'C1');
      await more(['x2'], cursor: 'C2');
      expect(service.queries[1]['cursor'], 'C1');
      expect(service.queries[1]['page'], '2');
      expect(service.queries[1]['limit'], '20');
      await more(['x3']);
      expect(service.queries[2]['cursor'], 'C2');
      expect(service.queries[2]['page'], '3');
    });

    test('no cursor is sent when page 1 returned none', () async {
      await page1(['x1']);
      await more(['x2']);
      expect(service.queries[1].containsKey('cursor'), isFalse);
      expect(service.queries[1]['page'], '2');
    });

    test('a response without nextCursor clears the stored one', () async {
      await page1(['x1'], cursor: 'C1');
      await more(['x2']);
      expect(n.state.nextCursor, isNull);
      await more(['x3']);
      expect(service.queries[2].containsKey('cursor'), isFalse);
    });

    test('a filter change drops the cursor', () async {
      await page1(['x1'], cursor: 'C1');
      final f = n.loadWithFilters(b);
      expect(n.state.nextCursor, isNull);
      expect(service.queries.last.containsKey('cursor'), isFalse);
      expect(service.queries.last['page'], '1');
      service.answer(_page(['y1']));
      await f;
    });

    test('refresh drops the cursor and sends page 1 without it', () async {
      await page1(['x1'], cursor: 'C1');
      final r = n.refresh();
      expect(n.state.nextCursor, isNull);
      expect(service.queries.last.containsKey('cursor'), isFalse);
      service.answer(_page(['x1'], cursor: 'C9'));
      await r;
      expect(n.state.nextCursor, 'C9');
    });

    test('a retry of a failed page 1 sends no cursor', () async {
      await page1(['x1'], cursor: 'C1');
      final r = n.refresh();
      service.fail();
      await r;
      expect(n.state.nextCursor, isNull);
      final r2 = n.refresh();
      expect(service.queries.last.containsKey('cursor'), isFalse);
      service.answer(_page(['x1']));
      await r2;
    });

    test('clear (sign-out) drops the cursor', () async {
      await page1(['x1'], cursor: 'C1');
      n.clear();
      expect(n.state.nextCursor, isNull);
    });

    test('a failed loadMore keeps the cursor and the list; retry repeats it',
        () async {
      await page1(['x1'], cursor: 'C1');
      final f = n.loadMore(force: true);
      service.fail();
      await f;
      expect(n.state.nextCursor, 'C1');
      expect(n.state.users.map((u) => u.id), ['x1']);
      expect(n.state.currentPage, 1);
      await more(['x2']);
      expect(service.queries[1], service.queries[2]);
      expect(service.queries[2]['cursor'], 'C1');
    });

    test('a person returned twice is listed once', () async {
      await page1(['x1', 'x2'], cursor: 'C1');
      await more(['x2', 'x3']);
      expect(n.state.users.map((u) => u.id), ['x1', 'x2', 'x3']);
    });

    test('no cursor, hasMore false: the list ends', () async {
      await page1(['x1'], hasMore: false);
      expect(n.state.hasMore, isFalse);
    });

    test('a short page with hasMore true allows another loadMore', () async {
      await page1(['x1'], cursor: 'C1');
      await more(['x2'], cursor: 'C2');
      expect(n.state.hasMore, isTrue);
      final f = n.loadMore(force: true);
      expect(service.queries.length, 3);
      service.answer(_page(['x3']));
      await f;
    });

    test('an empty page with a cursor keeps hasMore; three in a row stop it',
        () async {
      await page1(['x1'], cursor: 'C1');
      await more([], cursor: 'C2');
      expect(n.state.hasMore, isTrue);
      await more(['x1'], cursor: 'C3'); // only a repeat: still 0 new
      expect(n.state.hasMore, isTrue);
      await more([], cursor: 'C4');
      expect(n.state.hasMore, isFalse);
    });

    test('a page with new people resets the empty-page count', () async {
      await page1(['x1'], cursor: 'C1');
      await more([], cursor: 'C2');
      await more([], cursor: 'C3');
      await more(['x2'], cursor: 'C4');
      await more([], cursor: 'C5');
      await more([], cursor: 'C6');
      expect(n.state.hasMore, isTrue);
    });

    test('an empty page without a cursor ends the list as before', () async {
      await page1(['x1'], cursor: 'C1');
      await more([]);
      expect(n.state.hasMore, isFalse);
    });

    test('a number-paged page resets the empty-page count', () async {
      // Two all-repeat cursor pages, one server fallback page without a
      // cursor, then the cursor is back: one more all-repeat page must not
      // end the list.
      await page1(['x1'], cursor: 'C1');
      await more([], cursor: 'C2');
      await more(['x1'], cursor: 'C3');
      await more(['x2']);
      expect(n.state.hasMore, isTrue);
      await more(['x1'], cursor: 'C4');
      expect(n.state.hasMore, isTrue);
    });

    test('a loadMore with a cursor still in flight after a filter change '
        'appends nothing and restores no cursor', () async {
      await page1(['x1'], cursor: 'C1');
      final old = n.loadMore(force: true);
      final oldCall = service.calls.last;
      expect(service.queries.last['cursor'], 'C1');
      final reload = n.loadWithFilters(b);
      final reloadCall = service.calls.last;
      oldCall.complete(_page(['x2'], cursor: 'C2'));
      await old;
      expect(n.state.users, isEmpty);
      expect(n.state.nextCursor, isNull);
      expect(n.state.filters, b);
      reloadCall.complete(_page(['y1'], cursor: 'D1'));
      await reload;
      expect(n.state.users.map((u) => u.id), ['y1']);
      expect(n.state.nextCursor, 'D1');
      expect(n.state.currentPage, 1);
    });

    test('a page-1 load records when it arrived', () async {
      expect(n.state.loadedAt, isNull);
      await page1(['x1']);
      expect(n.state.loadedAt, isNotNull);
    });
  });

  group('blocked ids', () {
    late StreamController<String> blocks;
    late bool fast;

    setUp(() {
      blocks = StreamController<String>.broadcast(sync: true);
      addTearDown(blocks.close);
      fast = true;
      service = _FakeService();
      n = PartnerFilterNotifier(
        service,
        () => false,
        () => fast,
        DateTime.now,
        null,
        blocks.stream,
      );
    });

    test('a block while page 2 is in flight: the person is not appended, '
        'and a refresh does not bring them back', () async {
      await page1(['x1'], cursor: 'C1');
      final f = n.loadMore(force: true);
      blocks.add('x2');
      service.answer(_page(['x2', 'x3'], cursor: 'C2'));
      await f;
      expect(n.state.users.map((u) => u.id), ['x1', 'x3']);
      final r = n.refresh();
      service.answer(_page(['x2', 'x1']));
      await r;
      expect(n.state.users.map((u) => u.id), ['x1']);
    });

    test('a refresh clears local hides but not blocked ids', () async {
      n.hideLocally('s1');
      blocks.add('x2');
      n.clearLocalHides();
      expect(n.keptExclusions, {'x2'});
    });

    test('a page whose only new row was blocked does not count as empty',
        () async {
      await page1(['x1'], cursor: 'C1');
      blocks.add('x2');
      await more(['x2'], cursor: 'C2');
      expect(n.state.users.map((u) => u.id), ['x1']);
      await more([], cursor: 'C3');
      await more([], cursor: 'C4');
      // Two empty pages so far, not three.
      expect(n.state.hasMore, isTrue);
    });

    test('flag off: a block filters nothing', () async {
      fast = false;
      await page1(['x1', 'x2']);
      blocks.add('x2');
      expect(n.state.users.map((u) => u.id), ['x1', 'x2']);
      final r = n.refresh();
      service.answer(_page(['x1', 'x2']));
      await r;
      expect(n.state.users.map((u) => u.id), ['x1', 'x2']);
      expect(n.keptExclusions, isEmpty);
    });
  });

  group('slim rows', () {
    test('parse without follower arrays and read the counts', () {
      final u = Community.fromJson({
        '_id': 's1',
        'name': 's',
        'followersCount': 12,
        'followingCount': 3,
        'isFollowing': true,
      });
      expect(u.followers, isEmpty);
      expect(u.followings, isEmpty);
      expect(u.followerTotal, 12);
      expect(u.followingTotal, 3);
      expect(u.followedBy('me'), isTrue);
    });

    test('isFollowing false wins over everything', () {
      final u = Community.fromJson({
        '_id': 's1',
        'name': 's',
        'followersCount': 12,
        'isFollowing': false,
      });
      expect(u.followedBy('me'), isFalse);
    });

    test('a full row still reads its arrays', () {
      final u = Community.fromJson({
        '_id': 'f1',
        'name': 'f',
        'followers': ['me', 'other'],
        'following': ['z'],
      });
      expect(u.followerTotal, 2);
      expect(u.followingTotal, 1);
      expect(u.followedBy('me'), isTrue);
      expect(u.followedBy('nobody'), isFalse);
    });

    test('following then unfollowing a slim row flips followedBy and count',
        () {
      // The list never mutates a row; the profile screen reloads the full
      // document. A slim row re-read after each action must answer correctly.
      Map<String, dynamic> row(bool following, int count) => {
        '_id': 's1',
        'name': 's',
        'followersCount': count,
        'isFollowing': following,
      };
      final before = Community.fromJson(row(false, 12));
      final after = Community.fromJson(row(true, 13));
      expect(before.followedBy('me'), isFalse);
      expect(after.followedBy('me'), isTrue);
      expect(after.followerTotal, before.followerTotal + 1);
      final undone = Community.fromJson(row(false, 12));
      expect(undone.followedBy('me'), isFalse);
      expect(undone.followerTotal, 12);
    });
  });

  group('response model', () {
    test('reads nextCursor, null when absent or not a string', () {
      PaginatedCommunityResponse r(Object? c) => PaginatedCommunityResponse.fromBody(
        {'data': [], 'total': 0, 'pages': 1, 'nextCursor': c},
        page: 1,
      );
      expect(r('abc').nextCursor, 'abc');
      expect(r(null).nextCursor, isNull);
      expect(r(5).nextCursor, isNull);
    });
  });
}
