import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/session_expiry_handler.dart';

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

/// Every protected call 401s; the refresh endpoint answers [refresh].
MockClient _server(FutureOr<http.Response> Function() refresh) =>
    MockClient((req) async {
      if (req.url.path.endsWith(Endpoints.refreshTokenURL)) return refresh();
      return _json(401, {'error': 'Not authorized'});
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int authErrors;
  final client = ApiClient();

  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'expired', 'refreshToken': 'rt'});
    client.clearTokenCache();
    client.resetRefreshStateForTest();
    authErrors = 0;
    client.onAuthenticationError = () => authErrors++;
  });

  tearDown(() => client.onAuthenticationError = null);

  group('ApiClient raises the session-expired signal', () {
    test('when the refresh token is rejected (401)', () async {
      final r = await http.runWithClient(
        () => client.get('probe/1'),
        () => _server(() => _json(401, {'error': 'Invalid refresh token'})),
      );
      expect(r.statusCode, 401);
      expect(authErrors, 1);
    });

    test('when the user no longer exists (404 from refresh)', () async {
      await http.runWithClient(
        () => client.get('probe/2'),
        () => _server(() => _json(404, {'error': 'User not found'})),
      );
      expect(authErrors, 1);
    });
  });

  group('ApiClient does NOT log the user out', () {
    test('when the refresh endpoint is unreachable', () async {
      await http.runWithClient(
        () => client.get('probe/3'),
        () => _server(() => throw http.ClientException('Connection reset')),
      );
      expect(authErrors, 0);
    });

    test('when the refresh endpoint has a 5xx', () async {
      await http.runWithClient(
        () => client.get('probe/4'),
        () => _server(() => _json(503, {'error': 'unavailable'})),
      );
      expect(authErrors, 0);
    });

    test('on the first 401, before any refresh was tried', () async {
      // THE BUG this replaces: _handleResponse raised the callback on every
      // 401, so wiring it to logout would have logged out users whose access
      // token had merely expired.
      final r = await http.runWithClient(
        () => client.get('probe/5'),
        () => MockClient((req) async {
          if (req.url.path.endsWith(Endpoints.refreshTokenURL)) {
            return _json(200, {'token': 'fresh', 'refreshToken': 'rt2'});
          }
          final auth = req.headers['Authorization'] ?? '';
          return auth.endsWith('fresh')
              ? _json(200, {'data': {'balance': 5}})
              : _json(401, {'error': 'jwt expired'});
        }),
      );
      expect(r.success, isTrue);
      expect(authErrors, 0);
    });
  });

  group('SessionExpiryHandler', () {
    test('20 concurrent signals -> one reset, one navigation', () async {
      var resets = 0, routes = 0;
      var session = true;
      final h = SessionExpiryHandler(
        hasSession: () async => session,
        resetSession: () async {
          resets++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          session = false;
        },
        onExpired: () => routes++,
      );

      await Future.wait(List.generate(20, (_) => h.handle()));
      // Stragglers after the reset see no session and do nothing.
      await h.handle();

      expect(resets, 1);
      expect(routes, 1);
    });

    test('no stored session (already logged out) -> nothing happens',
        () async {
      var resets = 0, routes = 0;
      final h = SessionExpiryHandler(
        hasSession: () async => false,
        resetSession: () async => resets++,
        onExpired: () => routes++,
      );
      await h.handle();
      expect((resets, routes), (0, 0));
    });
  });
}
