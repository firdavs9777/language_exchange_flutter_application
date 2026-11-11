import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';

/// My Moments pages past the first 50 (it used to stop there), stops and
/// offers Retry when a page fails, and swaps an edited moment in place.
Map<String, dynamic> _moment(String id, [String text = 'x']) =>
    {'_id': id, 'description': text};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'token': 't'}));

  Future<T> withServer<T>(
    Future<http.Response> Function(http.Request) handler,
    Future<T> Function(ProviderContainer c, UserMomentsPagedNotifier n) body,
  ) {
    return http.runWithClient(() async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sub = c.listen(userMomentsPagedProvider('u1'), (_, __) {});
      addTearDown(sub.close);
      await c.read(userMomentsPagedProvider('u1').future);
      return body(c, c.read(userMomentsPagedProvider('u1').notifier));
    }, () => MockClient(handler));
  }

  http.Response page(List<String> ids, {required bool next}) => http.Response(
        jsonEncode({
          'success': true,
          'count': ids.length,
          'totalMoments': 61,
          'data': ids.map(_moment).toList(),
          'pagination': {'hasNextPage': next},
        }),
        200,
      );

  test('loads every page, not just the first', () async {
    await withServer((req) async {
      final p = int.parse(req.url.queryParameters['page']!);
      expect(req.url.queryParameters['limit'], '30');
      if (p == 1) return page(List.generate(30, (i) => 'a$i'), next: true);
      if (p == 2) return page(List.generate(30, (i) => 'b$i'), next: true);
      return page(['c0'], next: false);
    }, (c, n) async {
      expect(n.hasMore, isTrue);
      await n.loadMore();
      await n.loadMore();
      expect(c.read(userMomentsPagedProvider('u1')).value!.length, 61);
      expect(n.hasMore, isFalse);
    });
  });

  test('a failed page stops auto-paging until retry', () async {
    var failNext = true;
    var page2Calls = 0;
    await withServer((req) async {
      final p = int.parse(req.url.queryParameters['page']!);
      if (p == 1) return page(['a'], next: true);
      page2Calls++;
      if (failNext) return http.Response('{"success":false}', 500);
      return page(['b'], next: false);
    }, (c, n) async {
      await n.loadMore();
      await n.loadMore();
      expect(page2Calls, 1, reason: 'the second scroll fired another request');
      expect(n.loadMoreFailed, isTrue);
      failNext = false;
      await n.retry();
      expect(c.read(userMomentsPagedProvider('u1')).value!.map((m) => m.id), ['a', 'b']);
    });
  });

  test('an edit is swapped in place, a delete removed, without reloading', () async {
    var pageCalls = 0;
    await withServer((req) async {
      if (req.url.path.contains('/user/')) {
        pageCalls++;
        return page(['a', 'b'], next: false);
      }
      return http.Response(jsonEncode({'success': true, 'data': _moment('b', 'edited')}), 200);
    }, (c, n) async {
      await n.refreshMoment('b');
      n.removeMoment('a');
      final list = c.read(userMomentsPagedProvider('u1')).value!;
      expect(list.map((m) => m.id), ['b']);
      expect(list.single.description, 'edited');
      expect(pageCalls, 1);
    });
  });
}
