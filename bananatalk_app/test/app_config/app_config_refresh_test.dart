import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/app_config_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfigService extends AppConfigService {
  _FakeConfigService(this.answers);
  final List<AppConfig?> answers;
  int calls = 0;
  @override
  Future<AppConfig?> fetch() async => answers[calls++];
}

AppConfig _config({required bool boosts}) =>
    AppConfig.fromJson({'boostsEnabled': boosts});

void main() {
  late _FakeConfigService service;
  late ProviderContainer container;
  final t0 = DateTime(2026, 10, 18, 12);

  ProviderContainer make(List<AppConfig?> answers) {
    service = _FakeConfigService(answers);
    return ProviderContainer(overrides: [
      appConfigServiceProvider.overrideWithValue(service),
    ]);
  }

  tearDown(() => container.dispose());

  test('a switch flipped server-side shows after resume', () async {
    container = make([_config(boosts: false), _config(boosts: true)]);
    expect((await container.read(appConfigProvider.future))!.boostsEnabled, isFalse);
    container.read(appConfigRefreshStateProvider).lastFetch = t0;

    final replaced = await refreshAppConfig(container,
        now: t0.add(appConfigRefreshInterval));
    expect(replaced, isTrue);
    expect(container.read(appConfigProvider).valueOrNull!.boostsEnabled, isTrue);
    expect(service.calls, 2, reason: 'the rebuild reuses the fetched config');
  });

  test('a failed fetch keeps the loaded config', () async {
    container = make([_config(boosts: true), null]);
    await container.read(appConfigProvider.future);
    container.read(appConfigRefreshStateProvider).lastFetch = t0;

    final replaced = await refreshAppConfig(container,
        now: t0.add(const Duration(minutes: 5)));
    expect(replaced, isFalse);
    expect(container.read(appConfigProvider).valueOrNull!.boostsEnabled, isTrue);
  });

  test('a resume soon after a fetch does not fetch again', () async {
    container = make([_config(boosts: false), _config(boosts: true)]);
    await container.read(appConfigProvider.future);
    container.read(appConfigRefreshStateProvider).lastFetch = t0;

    final replaced = await refreshAppConfig(container,
        now: t0.add(const Duration(seconds: 30)));
    expect(replaced, isFalse);
    expect(service.calls, 1);
  });
}
