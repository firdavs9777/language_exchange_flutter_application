// Overflow sweep for every new AI Study hub / tab bar surface (owner request,
// 2026-10-14 final review). Each surface is pumped across widths 320 / 360 /
// 412, text scales 1.0 / 1.3 / 2.0 and locales en / de / ru / ko / ar (RTL),
// in light; dark adds nothing to layout, so it runs for en only. Any
// FlutterError (a "RenderFlex overflowed" included) fails the case.
//
// Text renders in the square test font, wider than any real font, so a pass
// here is a pessimistic pass.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/learning/achievement_model.dart';
import 'package:bananatalk_app/models/learning/challenge_model.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/learning/weekly_report_model.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart' hide WeakArea;
import 'package:bananatalk_app/pages/learning/main/sections/progress_card.dart';
import 'package:bananatalk_app/pages/learning/main/sections/recommended_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/spotlight_carousel.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/sections/today_pack_row.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/pages/learning/models/weekly_digest.dart';
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
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

import '../helpers/community_fixture.dart';

const _widths = [320.0, 360.0, 412.0];
const _scales = [1.0, 1.3, 2.0];
const _locales = ['en', 'de', 'ru', 'ko', 'ar'];

class _Case {
  const _Case(this.width, this.scale, this.locale, this.dark);
  final double width;
  final double scale;
  final String locale;
  final bool dark;
  @override
  String toString() =>
      '${width.toInt()}w x$scale $locale${dark ? ' dark' : ''}';
}

final _cases = [
  for (final w in _widths)
    for (final s in _scales) ...[
      for (final l in _locales) _Case(w, s, l, false),
      _Case(w, s, 'en', true),
    ],
];

Widget _app(_Case c, Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: Locale(c.locale),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: c.dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// Sizes the view for [c], runs [body], and fails on any reported error.
Future<void> _sweep(
  WidgetTester t,
  _Case c,
  Future<void> Function() body, {
  double height = 800,
}) async {
  t.view.physicalSize = Size(c.width, height);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = c.scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);

  final errors = <String>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) => errors.add(d.exceptionAsString());
  try {
    await body();
  } finally {
    FlutterError.onError = old;
  }
  expect(errors, isEmpty, reason: '$c');
  expect(t.takeException(), isNull, reason: '$c');
}

DailyPack _pack({
  bool needsLanguage = false,
  bool empty = false,
  bool complete = false,
  bool placed = true,
}) =>
    DailyPack(
      needsLanguage: needsLanguage,
      dateKey: '2026-10-14',
      weekKey: '2026-W42',
      dayInWeek: 2,
      requestedLevel: 'B2',
      servedLevel: 'B1',
      theme: empty
          ? null
          : const PackTheme(
              id: 'p',
              topic: 'Travel and everyday conversations abroad',
              level: 'beginner',
            ),
      stations: empty
          ? const []
          : const [PackStation(kind: 'grammar', status: StationStatus.todo)],
      packComplete: complete,
      levelPlaced: placed,
    );

final _progress = LearningProgress.fromJson({
  'totalXP': 123456,
  'level': 42,
  'currentStreak': 365,
  'dailyXP': 1200,
  'dailyGoal': 1500,
});

const _exhausted = TutorQuotaInfo(
    used: 10, cap: 10, remaining: 0, resetAt: null, unlimited: false);
const _low = TutorQuotaInfo(
    used: 8, cap: 10, remaining: 2, resetAt: null, unlimited: false);

AppConfig _cfg() => AppConfig(
      minVersion: '0',
      latestVersion: '0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      studyHubEnabled: true,
      studyVipOnlyFeatures: const {'photo'},
      announcements: [
        Announcement.fromJson({
          'id': 'a1',
          'emoji': '🎉',
          'title': 'A very long spotlight announcement title that keeps going '
              'well past one line on any phone',
          'body': 'b',
          'buttonLabel': 'Open the very long call to action now',
          'buttonUrl': 'https://banatalk.com/x',
        }),
        Announcement.fromJson({'id': 'a2', 'title': 'Second', 'body': 'b'}),
      ],
    );

/// Full hub: pack, recommended area, two spotlights (long title + button),
/// progress, exhausted / low / due / NEW badges and one VIP-locked tile.
List<Override> _hubOverrides() => [
      appConfigProvider.overrideWith((ref) async => _cfg()),
      userProvider.overrideWith(
          (ref) async => communityFixture(daysOld: kGuideWindowDays + 30)),
      isGuidePeriodProvider.overrideWith((ref) async => false),
      learningProgressProvider.overrideWith((ref) async => _progress),
      dailyPackProvider.overrideWith((ref) async => _pack(placed: false)),
      masteryProvider.overrideWith((ref) => Completer<MasterySummary>().future),
      weeklyReportProvider
          .overrideWith((ref) => Completer<WeeklyReport>().future),
      weeklyDigestProvider
          .overrideWith((ref) => Completer<WeeklyDigest>().future),
      weakAreasProvider.overrideWith((ref) async => [
            WeakArea(
              name: 'Past perfect continuous with irregular verbs',
              category: 'grammar',
              accuracy: 0.31,
              attempts: 12,
              recommendation: '',
            ),
          ]),
      tutorMemoryAndQuotasProvider.overrideWith((ref) =>
          Completer<({TutorMemory memory, Map<String, dynamic>? quotas})>()
              .future),
      tutorMemoryProvider
          .overrideWith((ref) => Completer<TutorMemory>().future),
      tutorQuotaProvider.overrideWithValue(const TutorQuotaState(
        chat: _exhausted,
        roleplay: _low,
        story: _exhausted,
        pronunciation: _low,
      )),
      vocabularyStatsProvider(null).overrideWith((ref) async =>
          VocabularyStats(
            total: 0,
            mastered: 0,
            learning: 0,
            newWords: 0,
            dueToday: 128,
            byLanguage: const {},
            bySrsLevel: const {},
            reviewStreak: 0,
            averageAccuracy: 0,
          )),
      examLanguagesProvider
          .overrideWith((ref) => Completer<List<ExamLanguage>>().future),
      challengesProvider
          .overrideWith((ref) => Completer<List<Challenge>>().future),
      achievementsProvider
          .overrideWith((ref) async => const <Achievement>[]),
      coinBalanceProvider.overrideWith((ref) async => 123456),
      featureSeenProvider.overrideWith((ref) async => const {'tutor'}),
      showAdsProvider.overrideWithValue(false),
    ];

final _configOff = appConfigProvider.overrideWith((ref) async => const AppConfig(
    minVersion: '0',
    latestVersion: '0',
    forceUpdate: false,
    iosUrl: '',
    androidUrl: '',
    releaseNotes: ''));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('StudyHub', () {
    for (final c in _cases) {
      testWidgets('$c', (t) async {
        await _sweep(t, c, () async {
          await t.pumpWidget(
              _app(c, const StudyHub(), overrides: _hubOverrides()));
          await t.pump(const Duration(milliseconds: 100));
          await t.pump(const Duration(milliseconds: 100));
          expect(find.byType(StudyHub), findsOneWidget);
          // The sections under test really rendered.
          expect(find.byType(SpotlightCarousel), findsOneWidget);
          expect(find.byType(TodayPackRow), findsOneWidget);
          expect(find.byType(RecommendedTile), findsOneWidget);
          expect(find.textContaining('Past perfect'), findsOneWidget);
          expect(find.byType(ProgressCard), findsOneWidget);
          expect(find.byType(StudyFeatureTile), findsNWidgets(12));
        });
      });
    }
  });

  group('StudyUpgradeSheet', () {
    for (final reason in StudyUpgradeReason.values) {
      for (final c in _cases) {
        testWidgets('${reason.name} $c', (t) async {
          await _sweep(t, c, height: 640, () async {
            await t.pumpWidget(_app(
              c,
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showStudyUpgradeSheet(context,
                        feature: StudyFeature.speak, reason: reason),
                    child: const Text('open'),
                  ),
                ),
              ),
              overrides: [_configOff],
            ));
            await t.tap(find.text('open'));
            await t.pumpAndSettle();
          });
        });
      }
    }
  });

  group('TodayPackRow', () {
    final states = {
      'normal': _pack(),
      'unplaced': _pack(placed: false),
      'needs language': _pack(needsLanguage: true),
      'empty': _pack(empty: true),
      'done': _pack(complete: true),
      'done unplaced': _pack(complete: true, placed: false),
    };
    for (final e in states.entries) {
      for (final c in _cases) {
        testWidgets('${e.key} $c', (t) async {
          await _sweep(t, c, () async {
            await t.pumpWidget(_app(
              c,
              Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TodayPackRow(
                    pack: e.value,
                    onOpen: () {},
                    onPickLanguage: () {},
                    onTakePlacement: () {},
                  ),
                ),
              ),
            ));
            await t.pump();
          });
        });
      }
    }
  });

  group('ProgressCard', () {
    for (final withData in [true, false]) {
      for (final c in _cases) {
        testWidgets('${withData ? 'data' : 'null'} $c', (t) async {
          await _sweep(t, c, () async {
            await t.pumpWidget(_app(
              c,
              Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ProgressCard(
                    progress: withData ? _progress : null,
                    onFullReport: () {},
                  ),
                ),
              ),
            ));
            await t.pump();
          });
        });
      }
    }
  });

  group('FloatingTabBar', () {
    for (var tab = 0; tab < 5; tab++) {
      for (final c in _cases) {
        testWidgets('tab $tab $c', (t) async {
          await _sweep(t, c, height: 640, () async {
            await t.pumpWidget(_app(
              c,
              Scaffold(
                body: Builder(builder: (context) {
                  final l = AppLocalizations.of(context)!;
                  final labels = [
                    l.study,
                    l.community,
                    l.chats,
                    l.moments,
                    l.profile,
                  ];
                  return Stack(children: [
                    FloatingTabBar(
                      selected: tab,
                      visible: true,
                      onSelect: (_) {},
                      items: [
                        for (final label in labels)
                          FloatingTabItem(
                            icon: Icons.circle_outlined,
                            activeIcon: Icons.circle,
                            label: label,
                            color: const Color(0xFF8B5CF6),
                            badgeCount: 120,
                          ),
                      ],
                    ),
                  ]);
                }),
              ),
            ));
            await t.pumpAndSettle();
            final pill = t.getRect(find.byKey(FloatingTabBar.pillKey));
            expect(pill.left, greaterThanOrEqualTo(0), reason: '$c');
            expect(pill.right, lessThanOrEqualTo(c.width), reason: '$c');
          });
        });
      }
    }
  });
}
