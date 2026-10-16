import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/install_referrer_pickup.dart';
import 'package:bananatalk_app/services/referral_service.dart';

void main() {
  group('inviteCodeFromInstallReferrer', () {
    test('reads code= from the referrer Play hands back', () {
      expect(inviteCodeFromInstallReferrer('code=ABCD2345'), 'ABCD2345');
      expect(inviteCodeFromInstallReferrer('utm_source=web&code=abcd2345&utm_medium=invite'), 'ABCD2345');
    });
    test('organic installs and junk give nothing', () {
      for (final r in [
        null,
        '',
        'utm_source=google-play&utm_medium=organic',
        'code=AB',
        'code=ABCD1890',
        'code=%E0%A4%A',
      ]) {
        expect(inviteCodeFromInstallReferrer(r), isNull, reason: '$r');
      }
    });
  });

  group('pickUpInstallReferrer', () {
    test('stores the code once', () async {
      SharedPreferences.setMockInitialValues({});
      var reads = 0;
      Future<String?> read() async {
        reads++;
        return 'code=ABCD2345';
      }

      await pickUpInstallReferrer(read: read, isAndroid: true);
      await pickUpInstallReferrer(read: read, isAndroid: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReferralPrefsKey), 'ABCD2345');
      expect(prefs.getBool(installReferrerCheckedPrefsKey), isTrue);
      expect(reads, 1);
    });

    test('a code from a tapped /i/ link wins', () async {
      SharedPreferences.setMockInitialValues({pendingReferralPrefsKey: 'LINK2345'});
      await pickUpInstallReferrer(read: () async => 'code=PLAY2345', isAndroid: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReferralPrefsKey), 'LINK2345');
    });

    test('not Android: never asks Play', () async {
      SharedPreferences.setMockInitialValues({});
      var reads = 0;
      await pickUpInstallReferrer(read: () async {
        reads++;
        return 'code=ABCD2345';
      }, isAndroid: false);
      expect(reads, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReferralPrefsKey), isNull);
    });

    test('Play unavailable: nothing stored, retried next launch', () async {
      SharedPreferences.setMockInitialValues({});
      await pickUpInstallReferrer(read: () async => throw Exception('no Play services'), isAndroid: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(installReferrerCheckedPrefsKey), isNull);
      expect(prefs.getString(pendingReferralPrefsKey), isNull);
    });
  });
}
