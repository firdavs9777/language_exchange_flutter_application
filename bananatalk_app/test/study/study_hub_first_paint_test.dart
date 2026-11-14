import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/learning/weekly_report_model.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart' hide WeakArea;
import 'package:bananatalk_app/pages/learning/daily/daily_pack_flow.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';
import 'package:bananatalk_app/services/study/study_hub_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/community_fixture.dart';

final _now = DateTime(2026, 11, 14, 9);
const _today = '2026-11-14';

StudyHubCache _cache() => StudyHubCache(now: () => _now);

StudyHubSnapshot _snapshot({String dateKey = _today}) => StudyHubSnapshot(
  dateKey: dateKey,
  language: 'Korean',
  level: 'B1',
  streak: 7,
  stationsDone: 2,
  stationsTotal: 4,
  savedAt: _now,
);

DailyPack _livePack({int done = 0}) => DailyPack(
  needsLanguage: false,
  dateKey: _today,
  weekKey: '2026-W46',
  dayInWeek: 2,
  language: 'ko',
  requestedLevel: 'A2',
  servedLevel: 'A2',
  level: 'A2',
  theme: const PackTheme(id: 'p', topic: 'Travel', level: 'beginner'),
  stations: [
    for (var i = 0; i < 3; i++)
      PackStation(
        kind: 'grammar',
        status: i < done ? StationStatus.done : StationStatus.todo,
        payload: const GrammarPayload(
          itemId: 'g1',
          unit: 1,
          section: 'A1',
          title: 'Grammar station title',
          explanation: 'e',
          examples: [],
          checks: [],
        ),
      ),
  ],
);

LearningProgress _progress(int streak) => LearningProgress.fromJson({
  'totalXP': 120,
  'level': 3,
  'currentStreak': streak,
  'dailyXP': 20,
  'dailyGoal': 50,
});

AppConfig _config() => const AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  studyHubEnabled: true,
);

class _Harness {
  final pack = Completer<DailyPack>();
  final progress = Completer<LearningProgress?>();
  int _packCalls = 0;
  int _progressCalls = 0;

  /// The first request is answered by the test; a refetch stays in flight.
  Future<DailyPack> nextPack() =>
      _packCalls++ == 0 ? pack.future : Completer<DailyPack>().future;
  Future<LearningProgress?> nextProgress() => _progressCalls++ == 0
      ? progress.future
      : Completer<LearningProgress?>().future;
  late final ProviderContainer container;
}

Future<_Harness> _pump(WidgetTester t, {Future<Community>? user}) async {
  final h = _Harness();
  final app = ProviderScope(
    overrides: [
      studyHubCacheProvider.overrideWithValue(_cache()),
      dailyPackProvider.overrideWith((ref) => h.nextPack()),
      learningProgressProvider.overrideWith((ref) => h.nextProgress()),
      userProvider.overrideWith((ref) => user ?? Completer<Community>().future),
      appConfigProvider.overrideWith((ref) async => _config()),
      masteryProvider.overrideWith((ref) => Completer<MasterySummary>().future),
      weeklyReportProvider.overrideWith(
        (ref) => Completer<WeeklyReport>().future,
      ),
      weakAreasProvider.overrideWith((ref) async => const <WeakArea>[]),
      tutorMemoryAndQuotasProvider.overrideWith(
        (ref) =>
            Completer<({TutorMemory memory, Map<String, dynamic>? quotas})>()
                .future,
      ),
      tutorMemoryProvider.overrideWith(
        (ref) => Completer<TutorMemory>().future,
      ),
      tutorQuotaProvider.overrideWithValue(TutorQuotaState.empty),
      vocabularyStatsProvider(
        null,
      ).overrideWith((ref) => Completer<VocabularyStats?>().future),
      featureSeenProvider.overrideWith((ref) async => const <String>{}),
      showAdsProvider.overrideWithValue(false),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StudyHub(),
    ),
  );
  await t.pumpWidget(app);
  h.container = ProviderScope.containerOf(t.element(find.byType(StudyHub)));
  // One more frame: the snapshot is read from disk (a microtask away).
  await t.pump();
  return h;
}

Future<void> _seed(StudyHubSnapshot s) async {
  SharedPreferences.setMockInitialValues({'userId': 'me'});
  await _cache().write('me', s);
}

String _streak(WidgetTester t, int n) =>
    AppLocalizations.of(t.element(find.byType(StudyHub)))!.studyStreakDays(n);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'me'}));

  testWidgets(
    "today's snapshot paints streak, level and progress on the first frame, no spinner",
    (t) async {
      await _seed(_snapshot());
      await _pump(t);
      expect(find.text(_streak(t, 7)), findsOneWidget);
      expect(find.text('Korean · B1'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('today-cached-row')), findsOneWidget);
    },
  );

  testWidgets("yesterday's snapshot is not painted", (t) async {
    await _seed(_snapshot(dateKey: '2026-11-13'));
    await _pump(t);
    expect(find.text('Korean · B1'), findsNothing);
    expect(find.text('2/4'), findsNothing);
    expect(find.byKey(const Key('today-cached-row')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets("another user's snapshot is not painted", (t) async {
    SharedPreferences.setMockInitialValues({'userId': 'someone-else'});
    await _cache().write('me', _snapshot());
    await _pump(t);
    expect(find.text('2/4'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the live answer replaces the cached values in place', (t) async {
    await _seed(_snapshot());
    final h = await _pump(t, user: Future.value(communityFixture()));
    expect(find.text('2/4'), findsOneWidget);

    h.progress.complete(_progress(5));
    h.pack.complete(_livePack());
    await t.pump();
    await t.pump();

    expect(find.text(_streak(t, 5)), findsOneWidget);
    expect(find.text(_streak(t, 7)), findsNothing);
    expect(find.text('2/4'), findsNothing);
    expect(find.byKey(const Key('today-cached-row')), findsNothing);
    expect(find.text('Start'), findsOneWidget, reason: 'the live row');
    // The pack's own level wins over the cached one.
    expect(find.text('Korean · A2'), findsOneWidget);
    expect(find.textContaining('B1'), findsNothing);
  });

  testWidgets('a rebuild after live data does not repaint from disk', (
    t,
  ) async {
    await _seed(_snapshot());
    final h = await _pump(t);
    h.progress.complete(_progress(5));
    h.pack.complete(_livePack());
    await t.pump();
    await t.pump();

    // A refresh: both answers are in flight again. The old snapshot (2/4,
    // B1) is still on disk and in memory, and must not come back.
    h.container.invalidate(dailyPackProvider);
    h.container.invalidate(learningProgressProvider);
    await t.pump();
    await t.pump();
    expect(find.text('2/4'), findsNothing);
    expect(find.text('Korean · B1'), findsNothing);
    expect(find.byKey(const Key('today-cached-row')), findsNothing);
    expect(find.text(_streak(t, 7)), findsNothing);
  });

  testWidgets(
    'a failed live request keeps the cached chips; the row hides as before',
    (t) async {
      await _seed(_snapshot());
      final h = await _pump(t);
      h.pack.completeError(Exception('offline'));
      h.progress.complete(null);
      await t.pump();
      await t.pump();
      expect(find.text(_streak(t, 7)), findsOneWidget);
      expect(find.text('Korean · B1'), findsOneWidget);
      // Today's error handling for the pack row: nothing.
      expect(find.byKey(const Key('today-cached-row')), findsNothing);
      expect(find.text('Start'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'the cached row is tappable and opens the pack flow once the real pack loads',
    (t) async {
      await _seed(_snapshot());
      final h = await _pump(t);
      await t.tap(find.byKey(const Key('today-cached-row')));
      await t.pump();
      expect(
        find.byType(DailyPackFlow),
        findsNothing,
        reason: 'waiting for the pack',
      );
      h.pack.complete(_livePack());
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(DailyPackFlow), findsOneWidget);
    },
  );

  testWidgets('a successful live load writes the snapshot for the next open', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({'userId': 'me'});
    final h = await _pump(t, user: Future.value(communityFixture()));
    h.progress.complete(_progress(5));
    h.pack.complete(_livePack(done: 1));
    await t.pump();
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    final s = await _cache().read('me');
    expect(s, isNotNull);
    expect(s!.dateKey, _today, reason: 'the device date, not the pack dateKey');
    expect(s.streak, 5);
    expect(s.stationsDone, 1);
    expect(s.stationsTotal, 3);
    expect(s.language, 'Korean');
    expect(s.level, 'A2');
  });

  testWidgets('sign-out clears the snapshot, so the next open paints nothing', (
    t,
  ) async {
    await _seed(_snapshot());
    await _cache().clearAll();
    expect(await _cache().read('me'), isNull);
    await _pump(t);
    expect(find.text('2/4'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
