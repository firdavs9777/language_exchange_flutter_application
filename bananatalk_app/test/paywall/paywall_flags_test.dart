import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

void main() {
  const flags = ['paywallEventsEnabled', 'offerEngineEnabled'];
  bool read(AppConfig c, String k) =>
      k == 'paywallEventsEnabled' ? c.paywallEventsEnabled : c.offerEngineEnabled;
  final providers = {
    'paywallEventsEnabled': paywallEventsEnabledProvider,
    'offerEngineEnabled': offerEngineEnabledProvider,
  };

  for (final k in flags) {
    group('AppConfig.$k', () {
      test('absent key -> false', () {
        expect(read(AppConfig.fromJson({}), k), false);
      });
      test('true -> true, false -> false', () {
        expect(read(AppConfig.fromJson({k: true}), k), true);
        expect(read(AppConfig.fromJson({k: false}), k), false);
      });
      test('non-bool values -> false, no throw', () {
        for (final v in <Object?>['true', 1, 'yes', null, <String>[], {}]) {
          expect(read(AppConfig.fromJson({k: v}), k), false, reason: '$v');
        }
      });
    });

    group('provider for $k', () {
      final p = providers[k]!;
      test('false while loading, then follows the config', () async {
        final completer = Completer<AppConfig?>();
        final container = ProviderContainer(overrides: [
          appConfigProvider.overrideWith((ref) => completer.future),
        ]);
        addTearDown(container.dispose);
        container.listen(p, (_, __) {});
        expect(container.read(p), false);
        completer.complete(AppConfig.fromJson({k: true}));
        await container.read(appConfigProvider.future);
        expect(container.read(p), true);
      });

      test('false on error and on a null config', () async {
        final err = ProviderContainer(overrides: [
          appConfigProvider.overrideWith((ref) async => throw StateError('x')),
        ]);
        addTearDown(err.dispose);
        err.listen(p, (_, __) {});
        await err.read(appConfigProvider.future).catchError((_) => null);
        expect(err.read(p), false);

        final nul = ProviderContainer(overrides: [
          appConfigProvider.overrideWith((ref) async => null),
        ]);
        addTearDown(nul.dispose);
        nul.listen(p, (_, __) {});
        await nul.read(appConfigProvider.future);
        expect(nul.read(p), false);
      });
    });
  }
}
