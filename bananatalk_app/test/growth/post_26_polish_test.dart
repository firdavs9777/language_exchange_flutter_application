import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/referral_service.dart';

AppConfig _config({bool matchesLayout = false}) => AppConfig(
      minVersion: '0.0.0',
      latestVersion: '0.0.0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      matchesLayoutEnabled: matchesLayout,
    );

Future<(int, String?)> _claimWith(http.Response Function() respond) async {
  SharedPreferences.setMockInitialValues({pendingReferralPrefsKey: 'ABC123'});
  final coins = await http.runWithClient(
    () => claimPendingReferral(ReferralService()),
    () => MockClient((_) async => respond()),
  );
  final prefs = await SharedPreferences.getInstance();
  return (coins, prefs.getString(pendingReferralPrefsKey));
}

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  group('shouldSeedInitialTab (cold-start race)', () {
    test('provider pre-set to 1 before first mount, initialIndex 0 -> stays 1',
        () {
      expect(
        shouldSeedInitialTab(
          initialIndex: 0,
          firstMount: true,
          valueAtInit: 1,
          valueNow: 1,
        ),
        isFalse,
      );
    });
    test('router write of 1 lands in the same frame as first mount -> kept',
        () {
      expect(
        shouldSeedInitialTab(
          initialIndex: 0,
          firstMount: true,
          valueAtInit: 0,
          valueNow: 1,
        ),
        isFalse,
      );
    });
    test('explicit /tabs/:index always seeds', () {
      expect(
        shouldSeedInitialTab(
          initialIndex: 3,
          firstMount: true,
          valueAtInit: 1,
          valueNow: 1,
        ),
        isTrue,
      );
    });
    test('re-mount (log out -> in) still resets a stale tab to 0', () {
      expect(
        shouldSeedInitialTab(
          initialIndex: 0,
          firstMount: false,
          valueAtInit: 4,
          valueNow: 4,
        ),
        isTrue,
      );
    });
    test('re-mount with a same-frame external write -> the write wins', () {
      expect(
        shouldSeedInitialTab(
          initialIndex: 0,
          firstMount: false,
          valueAtInit: 4,
          valueNow: 1,
        ),
        isFalse,
      );
    });
  });

  group('claimPendingReferral', () {
    test('success -> clears the code and returns invitee coins', () async {
      final (coins, left) = await _claimWith(() => _json(200, {
            'success': true,
            'data': {
              'credited': {'inviter': 50, 'invitee': 30},
            },
          }));
      expect(coins, 30);
      expect(left, isNull);
    });

    test('final 4xx (400) -> clears the code', () async {
      final (coins, left) = await _claimWith(
          () => _json(400, {'success': false, 'error': 'Already claimed'}));
      expect(coins, 0);
      expect(left, isNull);
    });

    test('404 unknown code -> clears the code (bad code)', () async {
      final (_, left) = await _claimWith(() => _json(
          404, {'success': false, 'error': unknownReferralCodeError}));
      expect(left, isNull);
    });

    test('404 feature off (REFERRALS_ENABLED=false) -> KEEPS the code',
        () async {
      final (coins, left) = await _claimWith(
          () => _json(404, {'success': false, 'error': 'Not found'}));
      expect(coins, 0);
      expect(left, 'ABC123');
    });

    test('404 from a server without the route (HTML) -> KEEPS the code',
        () async {
      final (_, left) = await _claimWith(
          () => http.Response('<pre>Cannot POST</pre>', 404));
      expect(left, 'ABC123');
    });

    test('network error -> keeps the code', () async {
      SharedPreferences.setMockInitialValues(
          {pendingReferralPrefsKey: 'ABC123'});
      final coins = await http.runWithClient(
        () => claimPendingReferral(ReferralService()),
        () => MockClient((_) async => throw http.ClientException('offline')),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(coins, 0);
      expect(prefs.getString(pendingReferralPrefsKey), 'ABC123');
    });

    test('5xx -> keeps the code', () async {
      final (_, left) =
          await _claimWith(() => _json(500, {'success': false}));
      expect(left, 'ABC123');
    });
  });

  group('shouldStorePendingReferral (/invite/:code)', () {
    test('no session -> store', () {
      expect(shouldStorePendingReferral(code: 'ABC', sessionToken: null),
          isTrue);
      expect(
          shouldStorePendingReferral(code: 'ABC', sessionToken: ''), isTrue);
    });
    test('session token exists -> do not store', () {
      expect(shouldStorePendingReferral(code: 'ABC', sessionToken: 'jwt'),
          isFalse);
    });
    test('empty code -> do not store', () {
      expect(
          shouldStorePendingReferral(code: '', sessionToken: null), isFalse);
      expect(shouldStorePendingReferral(code: null, sessionToken: null),
          isFalse);
    });
  });

  group('resolveMatchesLayoutForNewUser', () {
    test('healthy config -> its flag, no invalidate', () async {
      var invalidations = 0;
      final on = await resolveMatchesLayoutForNewUser(
        hasError: () => false,
        invalidate: () => invalidations++,
        read: () async => _config(matchesLayout: true),
      );
      expect(on, isTrue);
      expect(invalidations, 0);
    });

    test('provider already in error -> invalidate once, then read', () async {
      var invalidations = 0;
      final on = await resolveMatchesLayoutForNewUser(
        hasError: () => true,
        invalidate: () => invalidations++,
        read: () async =>
            invalidations > 0 ? _config(matchesLayout: true) : throw 'stale',
      );
      expect(on, isTrue);
      expect(invalidations, 1);
    });

    test('read errors -> invalidate once and retry', () async {
      var invalidations = 0;
      var reads = 0;
      final on = await resolveMatchesLayoutForNewUser(
        hasError: () => false,
        invalidate: () => invalidations++,
        read: () async {
          reads++;
          if (reads == 1) throw Exception('network');
          return _config(matchesLayout: true);
        },
      );
      expect(on, isTrue);
      expect(invalidations, 1);
      expect(reads, 2);
    });

    test('second failure -> false (/home), only one invalidate', () async {
      var invalidations = 0;
      final on = await resolveMatchesLayoutForNewUser(
        hasError: () => true,
        invalidate: () => invalidations++,
        read: () async => throw Exception('down'),
      );
      expect(on, isFalse);
      expect(invalidations, 1);
    });

    test('slow read -> false within the budget', () async {
      final on = await resolveMatchesLayoutForNewUser(
        hasError: () => false,
        invalidate: () {},
        read: () => Completer<AppConfig?>().future,
        budget: const Duration(milliseconds: 50),
      );
      expect(on, isFalse);
    });

    test('flag off (live build) -> false', () async {
      final on = await resolveMatchesLayoutForNewUser(
        hasError: () => false,
        invalidate: () {},
        read: () async => _config(),
      );
      expect(on, isFalse);
    });
  });
}
