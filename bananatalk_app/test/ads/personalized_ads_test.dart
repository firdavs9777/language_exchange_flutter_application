import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/ad_service.dart';

/// The personalizedAds privacy toggle was saved but never read: every ad was
/// requested with a plain `AdRequest()`, i.e. personalised.
void main() {
  group('buildAdRequest', () {
    test('personalised only when the user allows it', () {
      expect(buildAdRequest(personalizedAds: true).nonPersonalizedAds,
          isNot(true));
    });

    test('opted out: non-personalised', () {
      expect(buildAdRequest(personalizedAds: false).nonPersonalizedAds, isTrue);
    });

    test('not known yet: non-personalised', () {
      expect(buildAdRequest(personalizedAds: null).nonPersonalizedAds, isTrue);
    });
  });

  group('personalizedAdsProvider', () {
    Future<bool?> readFor(Map<String, dynamic> userJson) async {
      final container = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => Community.fromJson(userJson)),
      ]);
      addTearDown(container.dispose);
      await container.read(userProvider.future);
      return container.read(personalizedAdsProvider);
    }

    test('reads the stored setting', () async {
      expect(
        await readFor({
          '_id': 'u1',
          'privacySettings': {'personalizedAds': false},
        }),
        isFalse,
      );
    });

    test('no stored settings: the backend default (true)', () async {
      expect(await readFor({'_id': 'u1'}), isTrue);
    });
  });
}
