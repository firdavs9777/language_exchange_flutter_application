import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/interstitial_policy.dart';
import 'package:bananatalk_app/services/rewarded_unlock_policy.dart';

void main() {
  group('shouldShowInterstitial', () {
    bool call({
      bool flagOn = true,
      bool adFreeKnown = true,
      bool isAdFree = false,
      bool alreadyShownThisSession = false,
      bool loaded = true,
    }) =>
        shouldShowInterstitial(
          flagOn: flagOn,
          adFreeKnown: adFreeKnown,
          isAdFree: isAdFree,
          alreadyShownThisSession: alreadyShownThisSession,
          loaded: loaded,
        );

    test('flag off -> false always', () {
      expect(call(flagOn: false), isFalse);
      expect(call(flagOn: false, loaded: false), isFalse);
    });
    test('ad-free status unknown -> false', () {
      expect(call(adFreeKnown: false), isFalse);
    });
    test('VIP ad-free -> false', () {
      expect(call(isAdFree: true), isFalse);
    });
    test('already shown this session -> false', () {
      expect(call(alreadyShownThisSession: true), isFalse);
    });
    test('not loaded -> false', () {
      expect(call(loaded: false), isFalse);
    });
    test('all good -> true', () {
      expect(call(), isTrue);
    });
  });

  group('RewardedUnlockPolicy.resultFor', () {
    RewardedUnlockOutcome call({
      bool flagOn = true,
      String? featureKey = 'moment',
      bool featureRewardable = true,
      int? statusCode = 200,
      bool alreadyCredited = false,
    }) =>
        RewardedUnlockPolicy.resultFor(
          flagOn: flagOn,
          featureKey: featureKey,
          featureRewardable: featureRewardable,
          statusCode: statusCode,
          alreadyCredited: alreadyCredited,
        );

    test('flag off -> rewarded', () {
      expect(call(flagOn: false).result, 'rewarded');
    });
    test('flag on + 200 -> unlocked', () {
      final o = call();
      expect(o.result, 'unlocked');
      expect(o.messageKey, isNull);
    });
    test('flag on + 429 -> rewarded with limit message', () {
      final o = call(statusCode: 429);
      expect(o.result, 'rewarded');
      expect(o.messageKey, RewardedUnlockPolicy.limitReachedMessage);
    });
    test('flag on + null featureKey -> rewarded', () {
      expect(call(featureKey: null).result, 'rewarded');
    });
    test('flag on + wallpaper (not rewardable) -> rewarded, no call', () {
      final o = call(featureKey: 'wallpaper', featureRewardable: false);
      expect(o.result, 'rewarded');
      expect(o.shouldCallEndpoint, isFalse);
    });
    test('replay (alreadyCredited) -> rewarded, fail open', () {
      expect(call(alreadyCredited: true).result, 'rewarded');
    });
    test('other errors fail open', () {
      expect(call(statusCode: 500).result, 'rewarded');
      expect(call(statusCode: null).result, 'rewarded');
    });
    test('shouldCallEndpoint only when flag + key + rewardable', () {
      expect(RewardedUnlockPolicy.shouldCall(
          flagOn: true, featureKey: 'dm', featureRewardable: true), isTrue);
      expect(RewardedUnlockPolicy.shouldCall(
          flagOn: false, featureKey: 'dm', featureRewardable: true), isFalse);
      expect(RewardedUnlockPolicy.shouldCall(
          flagOn: true, featureKey: null, featureRewardable: true), isFalse);
    });
  });

  group('AppConfig rewarded fields', () {
    final base = {
      'minVersion': '1.0.0', 'latestVersion': '1.0.0', 'forceUpdate': false,
      'iosUrl': '', 'androidUrl': '', 'releaseNotes': '',
    };
    test('default off / empty', () {
      final c = AppConfig.fromJson(base);
      expect(c.rewardedLimitsEnabled, isFalse);
      expect(c.rewardedFeatures, isEmpty);
    });
    test('parsed from server', () {
      final c = AppConfig.fromJson({
        ...base,
        'rewardedLimitsEnabled': true,
        'rewardedFeatures': ['dm', 'moment'],
      });
      expect(c.rewardedLimitsEnabled, isTrue);
      expect(c.rewardedFeatures, ['dm', 'moment']);
    });
  });
}
