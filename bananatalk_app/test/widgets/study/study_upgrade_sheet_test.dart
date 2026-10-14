import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'dart:async';

import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

class _FakeCoinApi extends CoinApiClient {
  @override
  Future<ApiResponse> unlock(String featureKey) async =>
      ApiResponse(success: true, statusCode: 200);

  @override
  Future<int> getBalance() async => 500;
}

typedef _MemQ = ({TutorMemory memory, Map<String, dynamic>? quotas});

void main() {
  final events = <String, Map<String, Object>>{};
  setUp(() {
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events[n] = p;
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  Future<void> open(WidgetTester tester, StudyUpgradeReason reason) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Coins off: UnlockCta renders nothing, no network.
        appConfigProvider.overrideWith((ref) async =>
            const AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false,
                iosUrl: '', androidUrl: '', releaseNotes: '')),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showStudyUpgradeSheet(context,
                feature: StudyFeature.tutor, reason: reason),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('exhausted copy, VIP + Not now, logs shown', (tester) async {
    await open(tester, StudyUpgradeReason.exhausted);
    expect(find.text("You've used today's AI Tutor"), findsOneWidget);
    expect(find.text('Get VIP — unlimited'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(events['study_upgrade_sheet_shown'], {'feature': 'tutor', 'reason': 'exhausted'});
  });

  testWidgets('locked copy', (tester) async {
    await open(tester, StudyUpgradeReason.locked);
    expect(find.text('AI Tutor is a VIP feature'), findsOneWidget);
  });

  testWidgets('Not now closes', (tester) async {
    await open(tester, StudyUpgradeReason.exhausted);
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(find.text('Get VIP — unlimited'), findsNothing);
  });

  group('coins on', () {
    late ProviderContainer container;
    late int quotaBuilds;
    bool? result;

    Future<void> openWithCoins(WidgetTester tester, StudyUpgradeReason reason) async {
      quotaBuilds = 0;
      result = null;
      container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) async => const AppConfig(
            minVersion: '0', latestVersion: '0', forceUpdate: false,
            iosUrl: '', androidUrl: '', releaseNotes: '', coinsEnabled: true)),
        coinUnlockCatalogProvider.overrideWith((ref) async => const {
              'chat': CoinUnlockEntry(featureKey: 'chat', cost: 80, grant: 3),
            }),
        coinApiClientProvider.overrideWithValue(_FakeCoinApi()),
        coinBalanceProvider.overrideWith((ref) async => 500),
        tutorMemoryAndQuotasProvider.overrideWith((ref) {
          quotaBuilds++;
          return Completer<_MemQ>().future;
        }),
      ]);
      addTearDown(container.dispose);
      // Keep the autoDispose provider alive so an invalidate is observable.
      container.listen(tutorMemoryAndQuotasProvider, (_, __) {});
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showStudyUpgradeSheet(context,
                    feature: StudyFeature.tutor, reason: reason),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('locked sheet offers no coin unlock', (tester) async {
      await openWithCoins(tester, StudyUpgradeReason.locked);
      expect(find.text('AI Tutor is a VIP feature'), findsOneWidget);
      expect(find.byType(UnlockCta), findsNothing);
      expect(find.text('Unlock 3 for 💎80'), findsNothing);
    });

    testWidgets('exhausted coin unlock pops true and refreshes quotas', (tester) async {
      await openWithCoins(tester, StudyUpgradeReason.exhausted);
      expect(quotaBuilds, 1);
      await tester.tap(find.text('Unlock 3 for 💎80'));
      await tester.pumpAndSettle();
      container.read(tutorMemoryAndQuotasProvider);
      expect(result, isTrue);
      expect(quotaBuilds, 2);
      expect(events['study_upgrade_unlock'], {'feature': 'tutor', 'method': 'coins'});
    });
  });

  testWidgets('no overflow at 320 wide, text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async =>
            const AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false,
                iosUrl: '', androidUrl: '', releaseNotes: '')),
      ],
      child: MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 480), textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showStudyUpgradeSheet(context,
                  feature: StudyFeature.speak, reason: StudyUpgradeReason.exhausted),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
