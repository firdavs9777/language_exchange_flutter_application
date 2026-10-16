import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

const _allKeys = [
  'showCountryRegion',
  'showCity',
  'showAge',
  'showZodiac',
  'showOnlineStatus',
  'showGiftingLevel',
  'birthdayNotification',
  'personalizedAds',
  'emailNotifications',
  'weeklyDigest',
  'newMessageEmails',
  'newFollowerEmails',
  'securityAlerts',
  'anonymousProfileVisits',
];

Map<String, dynamic> _user(Map<String, dynamic>? privacy) => {
      '_id': 'u1',
      'name': 'A',
      'email': 'a@b.co',
      if (privacy != null) 'privacySettings': privacy,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivacySettings model', () {
    test('defaults: anonymousProfileVisits false, everything else true', () {
      final json = PrivacySettings.fromJson(const {}).toJson();
      expect(json.keys.toSet(), _allKeys.toSet());
      for (final k in _allKeys) {
        expect(json[k], k != 'anonymousProfileVisits', reason: k);
      }
    });

    test('round-trips all 14 keys', () {
      final flipped = {
        for (final k in _allKeys) k: k == 'anonymousProfileVisits',
      };
      expect(PrivacySettings.fromJson(flipped).toJson(), flipped);
    });
  });

  group('PrivacySettings.completeUpdate', () {
    test('lays the changes over the stored settings, sending every key', () {
      final out = PrivacySettings.completeUpdate(
        {'weeklyDigest': false, 'anonymousProfileVisits': true},
        {'showAge': false},
      );
      expect(out.keys.toSet(), _allKeys.toSet());
      expect(out['showAge'], isFalse);
      expect(out['weeklyDigest'], isFalse);
      expect(out['anonymousProfileVisits'], isTrue);
      expect(out['securityAlerts'], isTrue);
    });

    test('no stored settings falls back to the defaults', () {
      final out = PrivacySettings.completeUpdate(null, {'showCity': false});
      expect(out['showCity'], isFalse);
      expect(out['anonymousProfileVisits'], isFalse);
      expect(out['emailNotifications'], isTrue);
    });

    test('unknown keys are not sent', () {
      final out = PrivacySettings.completeUpdate(null, {'bogus': false});
      expect(out.containsKey('bogus'), isFalse);
    });
  });

  group('AuthService.updatePrivacySettings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'token': 't', 'userId': 'u1'});
    });

    test('sends the complete object merged over the stored settings',
        () async {
      Map<String, dynamic>? sent;
      final server = MockClient((req) async {
        if (req.method == 'GET' && req.url.path.endsWith('auth/me')) {
          return http.Response(
              jsonEncode({
                'data': _user({
                  'newFollowerEmails': false,
                  'weeklyDigest': false,
                  'anonymousProfileVisits': true,
                }),
              }),
              200);
        }
        if (req.method == 'PUT') {
          expect(req.url.path, endsWith('/u1'));
          sent = jsonDecode(req.body)['privacySettings']
              as Map<String, dynamic>;
          return http.Response(jsonEncode({'data': _user(sent)}), 200);
        }
        return http.Response('{}', 404);
      });

      await http.runWithClient(
        () => AuthService()
            .updatePrivacySettings(privacySettings: {'showAge': false}),
        () => server,
      );

      expect(sent, isNotNull);
      expect(sent!.keys.toSet(), _allKeys.toSet());
      expect(sent!['showAge'], isFalse);
      expect(sent!['newFollowerEmails'], isFalse);
      expect(sent!['weeklyDigest'], isFalse);
      expect(sent!['anonymousProfileVisits'], isTrue);
      expect(sent!['emailNotifications'], isTrue);
    });

    test('does not send a partial object when the stored settings fail',
        () async {
      var puts = 0;
      final server = MockClient((req) async {
        if (req.method == 'PUT') puts++;
        return http.Response('{"success":false}', 500);
      });

      await expectLater(
        http.runWithClient(
          () => AuthService()
              .updatePrivacySettings(privacySettings: {'showAge': false}),
          () => server,
        ),
        throwsException,
      );
      expect(puts, 0);
    });
  });
}
