import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_flow.dart';
import 'package:bananatalk_app/pages/learning/daily/placement/placement_screen.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_tab_opened_reporter.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart' show selectedTabProvider;
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';
import 'package:bananatalk_app/widgets/navigation/tab_reselect_scroll_to_top.dart';

typedef Logged = ({String name, Map<String, Object?> fields});

const _cfg = AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
);

DailyPack _pack() => const DailyPack(
      needsLanguage: false,
      language: 'ko',
      dateKey: '2026-09-07',
      weekKey: '2026-W37',
      dayInWeek: 1,
      theme: PackTheme(id: 'p1', topic: 'Work', level: 'intermediate'),
      stations: [
        PackStation(
          kind: 'grammar',
          status: StationStatus.todo,
          payload: GrammarPayload(
            itemId: 'g1', unit: 1, section: 'Present', title: 'am / is / are',
            explanation: 'Match the verb to the subject.',
            examples: ['I am here.'],
            checks: [PackCheck(prompt: 'She ___ my sister.', options: ['am', 'is', 'are'])],
          ),
        ),
      ],
    );

Widget _flowHost({required SubmitStation submit, DailyPack? pack}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyPackFlow(pack: pack ?? _pack(), submit: submit),
    );

Future<void> _finishStation(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('check-q0-opt1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('station-submit')));
  await tester.pumpAndSettle();
}

void main() {
  late List<Logged> logged;
  List<String> names() => logged.map((e) => e.name).toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    logged = [];
    studyLogSpy = (name, fields) => logged.add((name: name, fields: fields));
    // Flag off: nothing is sent and the app-wide container (and its real
    // app-config fetch) is never touched.
    studyLogContainer = ProviderContainer(
      overrides: [studyEventsEnabledProvider.overrideWithValue(false)],
    );
  });
  tearDown(() {
    studyLogSpy = null;
    studyLogContainer?.dispose();
    studyLogContainer = null;
  });

  group('DailyPackFlow', () {
    SubmitStation done(bool complete) =>
        (station, {answers = const [], reviews = const [], text = ''}) async =>
            StationResult(score: 2, total: 3, packComplete: complete);

    testWidgets('opening the pack logs session_started once', (tester) async {
      await tester.pumpWidget(_flowHost(submit: done(false)));
      await tester.pump();
      await tester.pumpWidget(_flowHost(submit: done(false))); // a rebuild
      await tester.pump();
      expect(names().where((n) => n == 'session_started'), hasLength(1));
      final s = logged.firstWhere((e) => e.name == 'session_started');
      expect(s.fields['language'], 'ko');
    });

    testWidgets(
        'a completed station logs step_started then step_finished with kind, score and total',
        (tester) async {
      await tester.pumpWidget(_flowHost(submit: done(false)));
      await _finishStation(tester);
      expect(names(), ['session_started', 'step_started', 'step_finished']);
      final started = logged[1].fields;
      expect(started['kind'], 'grammar');
      final finished = logged[2].fields;
      expect(finished['kind'], 'grammar');
      expect(finished['score'], 2);
      expect(finished['total'], 3);
    });

    testWidgets('the day-complete sheet logs session_finished', (tester) async {
      await tester.pumpWidget(_flowHost(submit: done(true)));
      await _finishStation(tester);
      expect(names(), isNot(contains('session_finished')),
          reason: 'not until the sheet shows');
      await tester.tap(find.byKey(const Key('station-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
      expect(names().where((n) => n == 'session_finished'), hasLength(1));
    });

    testWidgets('a day with nothing outstanding logs session_finished once',
        (tester) async {
      const empty = DailyPack(
        needsLanguage: false,
        dateKey: '2026-09-07',
        weekKey: '2026-W37',
        dayInWeek: 1,
        stations: [PackStation(kind: 'review', status: StationStatus.empty)],
      );
      await tester.pumpWidget(_flowHost(submit: done(true), pack: empty));
      await tester.pump();
      await tester.pump();
      expect(names(), ['session_started', 'session_finished']);
    });
  });

  group('PlacementScreen', () {
    Widget host({Future<Map<String, dynamic>> Function(List<int>)? submit}) =>
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlacementScreen(
            load: () async => List.generate(
              2,
              (i) => PackCheck(prompt: 'Question $i', options: const ['a', 'b']),
            ),
            submit: submit ?? (_) async => {'level': 'B1', 'book': 'x', 'correct': 1},
          ),
        );

    testWidgets('logs level_check_started once and level_check_finished with the level',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(names(), ['level_check_started']);
      await tester.tap(find.byKey(const Key('check-q0-opt1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('check-q1-opt0')));
      await tester.pumpAndSettle();
      expect(names(), ['level_check_started', 'level_check_finished']);
      expect(logged.last.fields['detail'], 'B1');
    });

    testWidgets('a failed submit logs no level_check_finished', (tester) async {
      await tester.pumpWidget(host(submit: (_) async => throw StateError('net')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('placement-skip')));
      await tester.pumpAndSettle();
      expect(names(), ['level_check_started']);
    });
  });

  group('StudyFeatureGroups', () {
    testWidgets('tapping a feature tile logs feature_opened with its slug',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) async => _cfg),
          tutorQuotaProvider.overrideWithValue(TutorQuotaState.empty),
          tutorMemoryAndQuotasProvider.overrideWith((ref) =>
              Completer<({TutorMemory memory, Map<String, dynamic>? quotas})>().future),
          featureSeenProvider.overrideWith(
              (ref) async => StudyFeature.values.map((f) => f.slug).toSet()),
          userProvider.overrideWith((ref) => Completer<Community>().future),
          vocabularyStatsProvider(null)
              .overrideWith((ref) => Completer<VocabularyStats?>().future),
          examLanguagesProvider
              .overrideWith((ref) => Completer<List<ExamLanguage>>().future),
          tutorMemoryProvider.overrideWith((ref) => Completer<TutorMemory>().future),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudyFeatureGroups(navigate: (_, __) {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(logged, isEmpty, reason: 'building the tiles logs nothing');
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(names(), ['feature_opened']);
      expect(logged.single.fields['kind'], StudyFeature.leaderboard.slug);
    });
  });

  group('StudyTabOpenedReporter', () {
    const studyTab = 0;
    late ProviderContainer container;

    Widget host() => UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Stack(children: [
              TabReselectScrollToTop(
                tab: studyTab,
                child: StudyTabOpenedReporter(child: SizedBox()),
              ),
            ]),
          ),
        );

    ProviderContainer make({required int selected}) {
      container = ProviderContainer(overrides: [
        studyEventsEnabledProvider.overrideWithValue(true),
        dailyPackProvider.overrideWith((ref) async => _pack()),
      ]);
      container.read(selectedTabProvider.notifier).state = selected;
      addTearDown(container.dispose);
      return container;
    }

    testWidgets('selecting the study tab logs tab_opened once, not on rebuild',
        (tester) async {
      make(selected: 2);
      await tester.pumpWidget(host());
      await tester.pump();
      expect(logged, isEmpty, reason: 'mounted while another tab is selected');

      container.read(selectedTabProvider.notifier).state = studyTab;
      await tester.pump();
      expect(names(), ['tab_opened']);

      await tester.pumpWidget(host()); // rebuild
      await tester.pump();
      expect(names(), ['tab_opened']);

      container.read(selectedTabProvider.notifier).state = 1;
      await tester.pump();
      container.read(selectedTabProvider.notifier).state = studyTab;
      await tester.pump();
      expect(names(), ['tab_opened', 'tab_opened'],
          reason: 'each time it becomes the selected tab');
    });

    testWidgets('mounted while already selected logs once, with the pack language',
        (tester) async {
      make(selected: studyTab);
      await container.read(dailyPackProvider.future);
      await tester.pumpWidget(host());
      await tester.pump();
      expect(names(), ['tab_opened']);
      expect(logged.single.fields['language'], 'ko');
    });
  });
}
