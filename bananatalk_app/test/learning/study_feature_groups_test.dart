import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';

const _cfg = AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
);

/// Writes wait for [gate], so a test can unmount before markSeen resolves.
class _SlowStore extends InMemorySharedPreferencesStore {
  _SlowStore() : super.empty();
  final gate = Completer<void>();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await gate.future;
    return super.setValue(valueType, key, value);
  }
}

/// Unlock always succeeds; no network.
class _FakeCoinApi extends CoinApiClient {
  int unlocks = 0;
  @override
  Future<ApiResponse> unlock(String featureKey) async {
    unlocks++;
    return ApiResponse(success: true, statusCode: 200);
  }

  @override
  Future<int> getBalance() async => 500;
}

const _coinsCfg = AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  coinsEnabled: true,
);

Widget harness({
  bool coins = false,
  CoinApiClient? coinApi,
  TutorQuotaState quota = TutorQuotaState.empty,
  Set<String> seen = const {},
  required List<String> pushed,
  Size size = const Size(390, 900),
  double textScale = 1.0,
  Locale? locale,
  int due = 0,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWith((ref) async => coins ? _coinsCfg : _cfg),
    tutorQuotaProvider.overrideWithValue(quota),
    tutorMemoryAndQuotasProvider.overrideWith((ref) =>
        Completer<({TutorMemory memory, Map<String, dynamic>? quotas})>().future),
    if (coinApi != null) coinApiClientProvider.overrideWithValue(coinApi),
    coinUnlockCatalogProvider.overrideWith((ref) async => const {
          'chat': CoinUnlockEntry(featureKey: 'chat', cost: 80, grant: 3),
        }),
    coinBalanceProvider.overrideWith((ref) async => 500),
    featureSeenProvider.overrideWith((ref) async => seen),
    // Never-completing: loading state is intended (not VIP, no target
    // language, no persona, no due words) and no real HTTP runs.
    userProvider.overrideWith((ref) => Completer<Community>().future),
    vocabularyStatsProvider(null).overrideWith(
      (ref) => due > 0
          ? Future.value(
              VocabularyStats(
                total: 0,
                mastered: 0,
                learning: 0,
                newWords: 0,
                dueToday: due,
                byLanguage: const {},
                bySrsLevel: const {},
                reviewStreak: 0,
                averageAccuracy: 0,
              ),
            )
          : Completer<VocabularyStats?>().future,
    ),
    examLanguagesProvider.overrideWith(
      (ref) => Completer<List<ExamLanguage>>().future,
    ),
    tutorMemoryProvider.overrideWith((ref) => Completer<TutorMemory>().future),
  ],
  child: MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: StudyFeatureGroups(
            navigate: (_, w) => pushed.add(w.runtimeType.toString()),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders three groups and twelve tiles', (tester) async {
    await tester.pumpWidget(harness(pushed: []));
    await tester.pumpAndSettle();
    expect(find.text('TALK'), findsOneWidget);
    expect(find.text('PRACTICE'), findsOneWidget);
    expect(find.text('PREPARE & COMPETE'), findsOneWidget);
    expect(find.byType(InkWell), findsNWidgets(12));
  });

  testWidgets('at most three NEW badges', (tester) async {
    await tester.pumpWidget(harness(pushed: []));
    await tester.pumpAndSettle();
    expect(find.text('NEW'), findsNWidgets(3));
  });

  testWidgets('exhausted tile opens the sheet instead of navigating', (
    tester,
  ) async {
    final pushed = <String>[];
    const quota = TutorQuotaState(
      chat: TutorQuotaInfo(
        used: 10,
        cap: 10,
        remaining: 0,
        resetAt: null,
        unlimited: false,
      ),
    );
    await tester.pumpWidget(harness(quota: quota, pushed: pushed));
    await tester.pumpAndSettle();
    expect(find.text('0 left'), findsOneWidget);
    await tester.tap(find.text('AI Tutor'));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);
    expect(find.text("You've used today's AI Tutor"), findsOneWidget);
  });

  testWidgets('free cap used but coin bonus left: no exhausted badge, tap navigates', (
    tester,
  ) async {
    final pushed = <String>[];
    const quota = TutorQuotaState(
      chat: TutorQuotaInfo(
        used: 10,
        cap: 10,
        remaining: 0,
        resetAt: null,
        unlimited: false,
        bonus: 2,
      ),
    );
    await tester.pumpWidget(harness(quota: quota, pushed: pushed));
    await tester.pumpAndSettle();
    expect(find.text('0 left'), findsNothing);
    expect(find.text('2 left'), findsOneWidget);
    await tester.tap(find.text('AI Tutor'));
    await tester.pumpAndSettle();
    expect(find.text("You've used today's AI Tutor"), findsNothing);
    expect(pushed, ['PersonaPickerScreen']);
  });

  testWidgets('exhausted + coin unlock: sheet pops true and the feature opens', (
    tester,
  ) async {
    final pushed = <String>[];
    final api = _FakeCoinApi();
    const quota = TutorQuotaState(
      chat: TutorQuotaInfo(
        used: 10,
        cap: 10,
        remaining: 0,
        resetAt: null,
        unlimited: false,
      ),
    );
    await tester.pumpWidget(
      harness(quota: quota, pushed: pushed, coins: true, coinApi: api),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Tutor'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock 3 for 💎80'), findsOneWidget);
    await tester.tap(find.text('Unlock 3 for 💎80'));
    await tester.pumpAndSettle();
    expect(api.unlocks, 1);
    expect(find.text("You've used today's AI Tutor"), findsNothing);
    expect(pushed, ['PersonaPickerScreen']);
  });

  testWidgets('tile removed before markSeen completes: no ref-after-dispose', (
    tester,
  ) async {
    final store = _SlowStore();
    SharedPreferencesStorePlatform.instance = store;
    final show = ValueNotifier(true);
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWith((ref) async => _cfg),
        tutorQuotaProvider.overrideWithValue(TutorQuotaState.empty),
        featureSeenProvider.overrideWith((ref) async => const <String>{}),
        userProvider.overrideWith((ref) => Completer<Community>().future),
        vocabularyStatsProvider(null)
            .overrideWith((ref) => Completer<VocabularyStats?>().future),
        examLanguagesProvider
            .overrideWith((ref) => Completer<List<ExamLanguage>>().future),
        tutorMemoryProvider.overrideWith((ref) => Completer<TutorMemory>().future),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: show,
            builder: (context, v, _) => v
                ? SingleChildScrollView(
                    child: StudyFeatureGroups(
                      navigate: (_, __) => show.value = false,
                    ),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lessons'));
    // navigate() unmounts the groups synchronously, before markSeen resolves.
    await tester.pumpAndSettle();
    expect(find.byType(StudyFeatureGroups), findsNothing);
    store.gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('quota not loaded: tap navigates', (tester) async {
    final pushed = <String>[];
    await tester.pumpWidget(harness(pushed: pushed));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    expect(pushed, ['LessonsScreen']);
  });

  testWidgets('tap marks the tile seen', (tester) async {
    await tester.pumpWidget(harness(pushed: []));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    expect(await FeatureSeenStore.readSeen(), contains('lessons'));
  });

  testWidgets('no overflow at 320 wide and text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(pushed: [], size: const Size(320, 900), textScale: 1.3),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final code in ['ru', 'de']) {
    testWidgets('long badges cannot overflow ($code, 320 wide, scale 1.3)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const info = TutorQuotaInfo(
        used: 10,
        cap: 10,
        remaining: 0,
        resetAt: null,
        unlimited: false,
      );
      const low = TutorQuotaInfo(
        used: 8,
        cap: 10,
        remaining: 2,
        resetAt: null,
        unlimited: false,
      );
      await tester.pumpWidget(
        harness(
          quota: const TutorQuotaState(
            chat: info,
            roleplay: low,
            story: info,
            photo: low,
            pronunciation: info,
          ),
          pushed: [],
          size: const Size(320, 900),
          textScale: 1.3,
          locale: Locale(code),
          due: 128,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
