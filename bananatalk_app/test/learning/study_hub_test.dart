import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/learning/achievement_model.dart';
import 'package:bananatalk_app/models/learning/challenge_model.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/learning/weekly_report_model.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart' hide WeakArea;
import 'package:bananatalk_app/pages/learning/models/weekly_digest.dart';
import 'package:bananatalk_app/pages/learning/main/learning_main_screen.dart';
import 'package:bananatalk_app/pages/learning/main/legacy_study_hub.dart';
import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/services/study_hub_flag_cache.dart';
import 'package:bananatalk_app/pages/learning/main/sections/spotlight_carousel.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/achievements_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/challenges_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/widgets/guides/guide_card.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';

import '../helpers/community_fixture.dart';

AppConfig cfg(bool on, {List<Announcement> announcements = const []}) =>
    AppConfig(
      minVersion: '0',
      latestVersion: '0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      studyHubEnabled: on,
      announcements: announcements,
    );

const _pack = DailyPack(
  needsLanguage: false,
  dateKey: '2026-10-14',
  weekKey: '2026-W42',
  dayInWeek: 2,
  requestedLevel: 'B2',
  servedLevel: 'B1',
  theme: PackTheme(id: 'p', topic: 'Travel', level: 'beginner'),
  stations: [
    PackStation(
      kind: 'grammar',
      status: StationStatus.todo,
      payload: GrammarPayload(
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

final _progress = LearningProgress.fromJson({
  'totalXP': 120,
  'level': 3,
  'currentStreak': 5,
  'dailyXP': 20,
  'dailyGoal': 50,
});

/// Every network provider the hub, the legacy screen and LearningMain's
/// listeners watch, answered from fixtures or left loading forever so no
/// real HTTP runs.
final _overrides = [
  dailyPackProvider.overrideWith((ref) async => _pack),
  masteryProvider.overrideWith((ref) => Completer<MasterySummary>().future),
  weeklyReportProvider.overrideWith((ref) => Completer<WeeklyReport>().future),
  weeklyDigestProvider.overrideWith((ref) => Completer<WeeklyDigest>().future),
  weakAreasProvider.overrideWith((ref) async => const <WeakArea>[]),
  tutorMemoryAndQuotasProvider.overrideWith(
    (ref) => Completer<({TutorMemory memory, Map<String, dynamic>? quotas})>()
        .future,
  ),
  tutorMemoryProvider.overrideWith((ref) => Completer<TutorMemory>().future),
  tutorQuotaProvider.overrideWithValue(TutorQuotaState.empty),
  vocabularyStatsProvider(
    null,
  ).overrideWith((ref) => Completer<VocabularyStats?>().future),
  examLanguagesProvider.overrideWith(
    (ref) => Completer<List<ExamLanguage>>().future,
  ),
  challengesProvider.overrideWith((ref) => Completer<List<Challenge>>().future),
  achievementsProvider.overrideWith((ref) async => const <Achievement>[]),
  coinBalanceProvider.overrideWith((ref) => Completer<int>().future),
  featureSeenProvider.overrideWith((ref) async => const <String>{}),
  showAdsProvider.overrideWithValue(false),
];

/// [daysOld] past the guide window by default, so only the guide tests see it.
Future<void> pump(
  WidgetTester t,
  bool on, {
  int daysOld = kGuideWindowDays + 30,
  List<Announcement> announcements = const [],
  bool noProgress = false,
  Future<AppConfig?> Function()? config,
  // The launch value remembered on the device (StudyHubFlagCache). Defaults
  // to the flag itself: a returning user whose phone already knows it.
  bool? cached,
  bool noCache = false,
}) async {
  StudyHubFlagCache.lastKnown = noCache ? null : (cached ?? on);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        ..._overrides,
        learningProgressProvider.overrideWith(
          (ref) async => noProgress ? null : _progress,
        ),
        appConfigProvider.overrideWith(
          (ref) => config != null
              ? config()
              : Future.value(cfg(on, announcements: announcements)),
        ),
        userProvider.overrideWith(
          (ref) async => communityFixture(daysOld: daysOld),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LearningMain(),
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 100));
}

/// Taps "See all features" in the visible hub and checks its Explore groups
/// moved from low on the page to near the top. Finders skip offstage routes,
/// so with two hubs mounted this is the one on top.
Future<void> expectSeeAllScrolls(WidgetTester t) async {
  final groupsFinder = find.byKey(StudyHub.groupsSectionKey);
  expect(groupsFinder, findsOneWidget);
  final viewport = t.getRect(find.byType(Scaffold).last);
  final before = t.getRect(groupsFinder).top;
  expect(
    before,
    greaterThan(viewport.height * 0.6),
    reason: 'precondition: the groups start low on the page',
  );

  await t.tap(find.text('See all features'));
  await t.pumpAndSettle();

  final groups = t.getRect(groupsFinder);
  expect(groups.top, lessThan(before));
  expect(groups.top, greaterThanOrEqualTo(viewport.top));
  expect(
    groups.top,
    lessThan(viewport.height * 0.4),
    reason: 'the groups now sit near the top of the viewport',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('flag off renders the legacy hub', (t) async {
    await pump(t, false);
    expect(find.byType(LegacyStudyHub), findsOneWidget);
    expect(find.byType(StudyHub), findsNothing);
  });

  testWidgets('no progress yet: the progress card still shows its shortcuts', (
    t,
  ) async {
    await pump(t, true, noProgress: true);
    await t.scrollUntilVisible(find.text('Full report'), 200);
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
  });

  group('cold start: page chosen once per launch from the remembered flag', () {
    testWidgets('remembered on, config still loading: hub at once, no spinner', (
      t,
    ) async {
      final c = Completer<AppConfig?>();
      await pump(t, true, config: () => c.future, cached: true);
      expect(find.byType(StudyHub), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('nothing remembered (first launch): waits for the server, '
        'then shows the hub when it is on', (t) async {
      final c = Completer<AppConfig?>();
      await pump(t, true, config: () => c.future, noCache: true);
      // A brief spinner, not the legacy page every new user used to get.
      expect(find.byType(LegacyStudyHub), findsNothing);
      expect(find.byType(StudyHub), findsNothing);
      c.complete(cfg(true));
      await t.pump();
      await t.pump();
      expect(find.byType(StudyHub), findsOneWidget);
      expect(StudyHubFlagCache.lastKnown, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StudyHubFlagCache.prefsKey), isTrue);
    });

    testWidgets('nothing remembered and the server is slow: legacy after the '
        'wait, then the hub as soon as the server says on', (t) async {
      final c = Completer<AppConfig?>();
      await pump(t, true, config: () => c.future, noCache: true);
      await t.pump(LearningMain.firstLaunchWaitForTests);
      expect(find.byType(LegacyStudyHub), findsOneWidget);
      c.complete(cfg(true));
      await t.pump();
      await t.pump();
      expect(find.byType(StudyHub), findsOneWidget);
      expect(find.byType(LegacyStudyHub), findsNothing);
      expect(StudyHubFlagCache.lastKnown, isTrue);
    });

    testWidgets('remembered off (stale) but the server says on: the hub, '
        'not the old page for the whole session', (t) async {
      final c = Completer<AppConfig?>();
      await pump(t, true, config: () => c.future, cached: false);
      expect(find.byType(LegacyStudyHub), findsOneWidget);
      c.complete(cfg(true));
      await t.pump();
      await t.pump();
      expect(find.byType(StudyHub), findsOneWidget);
    });

    testWidgets('remembered on but the server turned it off: the hub stays '
        'for this launch, off is remembered for the next', (t) async {
      final c = Completer<AppConfig?>();
      await pump(t, true, config: () => c.future, cached: true);
      c.complete(cfg(false));
      await t.pump();
      await t.pump();
      expect(find.byType(StudyHub), findsOneWidget);
      expect(StudyHubFlagCache.lastKnown, isFalse);
    });

    testWidgets('config error with nothing remembered: legacy', (t) async {
      await pump(
        t,
        true,
        config: () => Future.error(Exception('offline')),
        noCache: true,
      );
      expect(find.byType(LegacyStudyHub), findsOneWidget);
    });
  });

  testWidgets('config already loaded before the page mounts is still '
      'remembered (e.g. after re-login)', (t) async {
    await pump(t, true, noCache: true);
    expect(StudyHubFlagCache.lastKnown, isTrue);
    expect(find.byType(StudyHub), findsOneWidget);
  });

  test('the remembered flag survives logout (device-level key)', () {
    expect(isDeviceLevelPrefsKey(StudyHubFlagCache.prefsKey), isTrue);
  });

  testWidgets('flag on renders the hub with all three groups', (t) async {
    await pump(t, true);
    expect(find.byType(StudyHub), findsOneWidget);
    expect(find.byType(LegacyStudyHub), findsNothing);
    await t.scrollUntilVisible(find.text('PREPARE & COMPETE'), 200);
    expect(find.text('TALK'), findsOneWidget);
  });

  group('first-week guide (spec §7, §11)', () {
    final announcement = Announcement.fromJson({
      'id': 'a1',
      'title': 'Spotlight title',
      'body': 'Spotlight body',
    });

    testWidgets('a new user with nothing done sees the new guide', (t) async {
      await pump(t, true, daysOld: 1, announcements: [announcement]);
      expect(find.text('Your daily language gym'), findsOneWidget);
      expect(find.byType(GuideCard), findsOneWidget);
    });

    testWidgets('the spotlight carousel is absent while the guide shows', (
      t,
    ) async {
      await pump(t, true, daysOld: 1, announcements: [announcement]);
      expect(find.byType(GuideCard), findsOneWidget);
      expect(find.byType(SpotlightCarousel), findsNothing);
    });

    testWidgets('outside the guide window the carousel shows instead', (
      t,
    ) async {
      await pump(t, true, announcements: [announcement]);
      expect(find.byType(GuideCard), findsNothing);
      expect(find.byType(SpotlightCarousel), findsOneWidget);
      expect(find.text('Spotlight title'), findsOneWidget);
    });

    testWidgets('"See all features" scrolls the Explore groups into view', (
      t,
    ) async {
      // A short viewport so the groups start low on the page.
      t.view.physicalSize = const Size(390, 480);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      await pump(t, true, daysOld: 1);
      await expectSeeAllScrolls(t);
    });

    testWidgets('"Start today\'s pack" opens the pack', (t) async {
      await pump(t, true, daysOld: 1);
      await t.tap(find.text("Start today's pack"));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Grammar station title'),
        findsOneWidget,
        reason: "the guide's primary action opens today's pack",
      );
    });
  });

  testWidgets('no overflow at 320 wide and text scale 1.3', (t) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(t, true, daysOld: 1);
    expect(t.takeException(), isNull);
    await t.scrollUntilVisible(find.text('PREPARE & COMPETE'), 200);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'two hubs mounted at once (daily_drop pushes a second LearningMain) '
    'share no key, and See all features scrolls the visible one',
    (t) async {
      t.view.physicalSize = const Size(390, 480);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      await pump(t, true, daysOld: 1);
      t
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (_) => const LearningMain()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(StudyHub, skipOffstage: false), findsNWidgets(2));

      await expectSeeAllScrolls(t);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('re-tapping the AI Study tab scrolls the hub to the top', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 480);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await pump(t, true);
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    ScrollPosition position() => t.state<ScrollableState>(scrollable).position;

    position().jumpTo(600);
    await t.pump();
    expect(position().pixels, 600);

    final container = ProviderScope.containerOf(
      t.element(find.byType(StudyHub)),
    );
    // Another tab's reselect leaves the hub alone.
    container.read(tabReselectProvider.notifier).state = (tab: 2, seq: 1);
    await t.pumpAndSettle();
    expect(position().pixels, 600);

    container.read(tabReselectProvider.notifier).state = (tab: 0, seq: 2);
    await t.pumpAndSettle();
    expect(position().pixels, 0);
  });

  group('header language chip (spec §3)', () {
    testWidgets('shows the target language with the CEFR level', (t) async {
      await pump(t, true);
      expect(find.text('Korean · B1'), findsOneWidget);
    });

    test('packCefrLevel: served, else requested, only A1-C2', () {
      DailyPack p({String? served, String? requested}) => DailyPack(
        needsLanguage: false,
        dateKey: 'd',
        weekKey: 'w',
        dayInWeek: 1,
        servedLevel: served,
        requestedLevel: requested,
      );
      expect(packCefrLevel(p(served: 'B1', requested: 'B2')), 'B1');
      expect(packCefrLevel(p(requested: 'a2')), 'A2');
      expect(packCefrLevel(p(served: 'beginner', requested: 'C1')), 'C1');
      expect(packCefrLevel(p(served: 'intermediate')), isNull);
      expect(packCefrLevel(p()), isNull);
      expect(packCefrLevel(null), isNull);
    });
  });
}
