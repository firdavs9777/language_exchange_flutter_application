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
  learningProgressProvider.overrideWith((ref) async => _progress),
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
}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        ..._overrides,
        appConfigProvider.overrideWith(
          (ref) async => cfg(on, announcements: announcements),
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('flag off renders the legacy hub', (t) async {
    await pump(t, false);
    expect(find.byType(LegacyStudyHub), findsOneWidget);
    expect(find.byType(StudyHub), findsNothing);
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
      final viewport = t.getRect(find.byType(Scaffold).first);
      final before = t.getRect(find.byKey(StudyHub.groupsKey)).top;
      expect(
        before,
        greaterThan(viewport.height * 0.6),
        reason: 'precondition: the groups start low on the page',
      );

      await t.tap(find.text('See all features'));
      await t.pumpAndSettle();

      final groups = t.getRect(find.byKey(StudyHub.groupsKey));
      expect(groups.top, lessThan(before));
      expect(groups.top, greaterThanOrEqualTo(viewport.top));
      expect(
        groups.top,
        lessThan(viewport.height * 0.4),
        reason: 'the groups now sit near the top of the viewport',
      );
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
}
