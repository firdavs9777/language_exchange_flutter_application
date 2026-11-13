import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

void main() {
  group('AppConfig.communityFastListEnabled', () {
    test('absent key -> false', () {
      expect(AppConfig.fromJson({}).communityFastListEnabled, false);
    });
    test('true -> true', () {
      expect(
        AppConfig.fromJson({'communityFastListEnabled': true})
            .communityFastListEnabled,
        true,
      );
    });
    test('false -> false', () {
      expect(
        AppConfig.fromJson({'communityFastListEnabled': false})
            .communityFastListEnabled,
        false,
      );
    });
    test('non-bool values -> false, no throw', () {
      for (final v in <Object?>['true', 1, 'yes', null, <String>[], {}]) {
        expect(
          AppConfig.fromJson({'communityFastListEnabled': v})
              .communityFastListEnabled,
          false,
          reason: 'value $v',
        );
      }
    });
  });

  group('communityFastListEnabledProvider', () {
    test('false while loading, then follows the config', () async {
      final completer = Completer<AppConfig?>();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => completer.future),
      ]);
      addTearDown(container.dispose);
      container.listen(communityFastListEnabledProvider, (_, __) {});

      expect(container.read(communityFastListEnabledProvider), false);
      completer.complete(
        AppConfig.fromJson({'communityFastListEnabled': true}),
      );
      await container.read(appConfigProvider.future);
      expect(container.read(communityFastListEnabledProvider), true);
    });

    test('false on error and on a null config', () async {
      final errContainer = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) async => throw StateError('x')),
      ]);
      addTearDown(errContainer.dispose);
      errContainer.listen(communityFastListEnabledProvider, (_, __) {});
      await errContainer.read(appConfigProvider.future).catchError((_) => null);
      expect(errContainer.read(communityFastListEnabledProvider), false);

      final nullContainer = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) async => null),
      ]);
      addTearDown(nullContainer.dispose);
      nullContainer.listen(communityFastListEnabledProvider, (_, __) {});
      await nullContainer.read(appConfigProvider.future);
      expect(nullContainer.read(communityFastListEnabledProvider), false);
    });
  });
}
