import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_upload_handler.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

/// Profile audit 2026-11-11: contract fixes the screens depend on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 't', 'userId': 'u1'});
  });

  group('PhotoUploadHandler.deleteAllExtras', () {
    test('returns what the last DELETE left, as CDN urls, with no re-fetch', () async {
      var gets = 0;
      final server = MockClient((req) async {
        if (req.method == 'GET') gets++;
        final index = int.parse(req.url.pathSegments.last);
        final left = List.generate(index, (i) => 'https://cdn/p$i.jpg');
        return http.Response(
          jsonEncode({'images': left.map((u) => 'origin:$u').toList(), 'imageUrls': left}),
          200,
        );
      });

      final result = await http.runWithClient(
        () => const PhotoUploadHandler(userId: 'u1').deleteAllExtras(
          existingCount: 3,
          noTokenMessage: 'no token',
          failedMessage: 'failed',
          successMessage: 'ok',
        ),
        () => server,
      );

      expect(result.success, isTrue);
      expect(result.imageUrls, ['https://cdn/p0.jpg']);
      expect(gets, 0);
    });

    test('a failed DELETE is a failure carrying what is left, not success', () async {
      final server = MockClient((req) async {
        final index = int.parse(req.url.pathSegments.last);
        if (index == 1) return http.Response('{"error":"nope"}', 500);
        return http.Response(jsonEncode({'imageUrls': ['a', 'b']}), 200);
      });

      final result = await http.runWithClient(
        () => const PhotoUploadHandler(userId: 'u1').deleteAllExtras(
          existingCount: 3,
          noTokenMessage: 'no token',
          failedMessage: 'failed',
          successMessage: 'ok',
        ),
        () => server,
      );

      expect(result.success, isFalse);
      expect(result.imageUrls, ['a', 'b']);
    });
  });

  test('deletePhoto names the URL it means', () async {
    Uri? hit;
    final server = MockClient((req) async {
      hit = req.url;
      return http.Response(jsonEncode({'imageUrls': <String>[]}), 200);
    });
    await http.runWithClient(
      () => const PhotoUploadHandler(userId: 'u1').deletePhoto(
        2,
        expectedUrl: 'https://cdn/p2.jpg',
        noTokenMessage: 'x',
        failedMessage: 'x',
        defaultSuccessMessage: 'x',
      ),
      () => server,
    );
    expect(hit!.path, endsWith('/photo/2'));
    expect(hit!.queryParameters['url'], 'https://cdn/p2.jpg');
  });

  test('an empty followers/following list stays empty (no per-id re-fetch)', () async {
    var requests = 0;
    final server = MockClient((req) async {
      requests++;
      return http.Response(jsonEncode({'success': true, 'count': 0, 'data': []}), 200);
    });
    final followers = await http.runWithClient(
      () => AuthService().getFollowersUser(id: 'u1'),
      () => server,
    );
    final following = await http.runWithClient(
      () => AuthService().getFollowingsUser(id: 'u1'),
      () => server,
    );
    expect(followers, isEmpty);
    expect(following, isEmpty);
    expect(requests, 2);
  });
}
