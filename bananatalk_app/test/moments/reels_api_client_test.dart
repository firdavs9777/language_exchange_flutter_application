import 'dart:convert';

import 'package:bananatalk_app/services/reels_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;

  ReelsApiClient clientReplying(Map<String, dynamic> body) {
    requests = [];
    return ReelsApiClient(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(json.encode(body), 200);
      }),
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('new server cursor is sent URI-encoded exactly once', () async {
    final api = clientReplying({'success': true, 'data': []});
    await api.getReels(before: 's2:1700000000000:12');

    expect(
      requests.single.url.toString(),
      contains('before=s2%3A1700000000000%3A12'),
    );
    expect(requests.single.url.toString(), isNot(contains('%253A')));
    expect(
      requests.single.url.queryParameters['before'],
      's2:1700000000000:12',
    );
  });

  test('old ISO date cursor is still sent verbatim', () async {
    final api = clientReplying({'success': true, 'data': []});
    await api.getReels(before: '2026-11-01T10:00:00.000Z');

    expect(
      requests.single.url.queryParameters['before'],
      '2026-11-01T10:00:00.000Z',
    );
  });

  test('limit is still sent, and no before when there is no cursor', () async {
    final api = clientReplying({'success': true, 'data': []});
    await api.getReels(limit: 7);

    expect(requests.single.url.queryParameters['limit'], '7');
    expect(requests.single.url.queryParameters.containsKey('before'), isFalse);
  });

  test('a cursor with +, & and space reaches the server unchanged', () async {
    final api = clientReplying({'success': true, 'data': []});
    const cursor = 'a+b&c d';
    await api.getReels(before: cursor);

    expect(requests.single.url.queryParameters['before'], cursor);
    expect(requests.single.url.queryParameters.length, 2); // limit + before
  });

  test('nextCursor is returned as the exact opaque string', () async {
    final api = clientReplying({
      'success': true,
      'data': [],
      'nextCursor': 's2:1700000000000:24',
    });
    final page = await api.getReels();

    expect(page.nextCursor, 's2:1700000000000:24');
  });

  test('missing or null nextCursor yields null', () async {
    final a = await clientReplying({'success': true, 'data': []}).getReels();
    final b = await clientReplying({
      'success': true,
      'data': [],
      'nextCursor': null,
    }).getReels();

    expect(a.nextCursor, isNull);
    expect(b.nextCursor, isNull);
  });
}
