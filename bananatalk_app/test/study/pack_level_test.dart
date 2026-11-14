import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_flow.dart';
import 'package:bananatalk_app/pages/learning/daily/placement/placement_screen.dart';
import 'package:bananatalk_app/pages/learning/main/sections/learn_tab.dart';
import 'package:bananatalk_app/pages/learning/main/sections/today_pack_row.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';

import '../helpers/community_fixture.dart';

const _fromTomorrow = 'From tomorrow your practice moves to B2.';

Map<String, dynamic> _packJson({Map<String, dynamic> extra = const {}}) => {
  'needsLanguage': false,
  'dateKey': '2026-11-14',
  'weekKey': '2026-W46',
  'dayInWeek': 6,
  'language': 'ko',
  'requestedLevel': 'A2',
  'servedLevel': 'A2',
  'theme': {'id': 't1', 'topic': 'Work', 'level': 'A2'},
  'stations': <Object>[],
  ...extra,
};

DailyPack _pack({
  bool? levelMeasured,
  bool levelPlaced = true,
  String? level,
}) => DailyPack.fromJson(
  _packJson(
    extra: {
      'levelPlaced': levelPlaced,
      if (levelMeasured != null) 'levelMeasured': levelMeasured,
      if (level != null) 'level': level,
      'stations': [
        {
          'kind': 'review',
          'status': 'todo',
          'payload': {'words': []},
        },
      ],
    },
  ),
);

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Widget _row(DailyPack p) => _app(
  Scaffold(
    body: TodayPackRow(
      pack: p,
      onOpen: () {},
      onPickLanguage: () {},
      onTakePlacement: () {},
    ),
  ),
);

const _grammar = PackStation(
  kind: 'grammar',
  status: StationStatus.todo,
  payload: GrammarPayload(
    itemId: 'g1',
    unit: 1,
    section: 'Present',
    title: 'am / is / are',
    explanation: 'Match the verb to the subject.',
    examples: ['I am here.'],
    checks: [
      PackCheck(prompt: 'She ___ my sister.', options: ['am', 'is', 'are']),
    ],
  ),
);

DailyPack _flowPack() => const DailyPack(
  needsLanguage: false,
  language: 'ko',
  dateKey: '2026-11-14',
  weekKey: '2026-W46',
  dayInWeek: 6,
  theme: PackTheme(id: 'p1', topic: 'Work', level: 'A2'),
  stations: [_grammar],
);

Widget _flow(StationResult result) => _app(
  DailyPackFlow(
    pack: _flowPack(),
    submit:
        (station, {answers = const [], reviews = const [], text = ''}) async =>
            result,
  ),
);

Future<void> _finishStation(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('check-q0-opt1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('station-submit')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    studyLogSpy = (_, __) {};
  });
  tearDown(() => studyLogSpy = null);

  test(
    'a pack without levelMeasured parses as null and a completion without levelChange as null',
    () {
      final pack = DailyPack.fromJson(_packJson());
      expect(pack.levelMeasured, isNull);
      expect(pack.level, isNull);
      expect(
        StationResult.fromJson({'score': 1, 'total': 2}).levelChange,
        isNull,
      );
      expect(
        StationResult.fromJson({
          'score': 1,
          'total': 2,
          'levelChange': null,
        }).levelChange,
        isNull,
      );
      final measured = DailyPack.fromJson(
        _packJson(extra: {'levelMeasured': false, 'level': 'B1'}),
      );
      expect(measured.levelMeasured, isFalse);
      expect(measured.level, 'B1');
      final change = StationResult.fromJson({
        'score': 1,
        'total': 2,
        'levelChange': {'from': 'B1', 'to': 'B2'},
      }).levelChange;
      expect(change?.from, 'B1');
      expect(change?.to, 'B2');
    },
  );

  group('Find your level on the pack row', () {
    testWidgets(
      'levelMeasured false offers it, even when levelPlaced is true',
      (t) async {
        await t.pumpWidget(
          _row(_pack(levelMeasured: false, levelPlaced: true)),
        );
        expect(find.byKey(const Key('today-take-placement')), findsOneWidget);
      },
    );

    testWidgets('levelMeasured true does not, even when levelPlaced is false', (
      t,
    ) async {
      await t.pumpWidget(_row(_pack(levelMeasured: true, levelPlaced: false)));
      expect(find.byKey(const Key('today-take-placement')), findsNothing);
    });

    testWidgets('absent levelMeasured follows levelPlaced as today', (t) async {
      await t.pumpWidget(_row(_pack(levelPlaced: false)));
      expect(find.byKey(const Key('today-take-placement')), findsOneWidget);
      await t.pumpWidget(_row(_pack(levelPlaced: true)));
      expect(find.byKey(const Key('today-take-placement')), findsNothing);
    });
  });

  group('hub chip', () {
    Widget chips(Future<DailyPack> Function() pack) => _app(
      const Scaffold(body: StudyHeaderChips()),
      overrides: [
        userProvider.overrideWith((ref) async => communityFixture()),
        learningProgressProvider.overrideWith(
          (ref) async => LearningProgress.fromJson({
            'totalXP': 1,
            'level': 3,
            'currentStreak': 2,
            'dailyXP': 0,
            'dailyGoal': 50,
          }),
        ),
        dailyPackProvider.overrideWith((ref) => pack()),
      ],
    );

    testWidgets('shows the pack level once the pack has loaded', (t) async {
      await t.pumpWidget(
        chips(() async => _pack(levelMeasured: true, level: 'B2')),
      );
      await t.pumpAndSettle();
      expect(find.text('Korean · B2'), findsOneWidget);
    });

    testWidgets('without a pack level it shows what it shows today', (t) async {
      await t.pumpWidget(chips(() async => _pack()));
      await t.pumpAndSettle();
      expect(find.text('Korean · A2'), findsOneWidget);
    });

    testWidgets('before the pack loads it shows the language alone', (t) async {
      await t.pumpWidget(chips(() => Future.any<DailyPack>([])));
      await t.pump();
      await t.pump();
      expect(find.text('Korean'), findsOneWidget);
    });
  });

  group('level change line', () {
    testWidgets(
      'a completion with levelChange B1 -> B2 shows the from-tomorrow line',
      (t) async {
        await t.pumpWidget(
          _flow(
            const StationResult(
              score: 2,
              total: 3,
              packComplete: true,
              levelChange: LevelChange(from: 'B1', to: 'B2'),
            ),
          ),
        );
        await _finishStation(t);
        expect(
          find.text(_fromTomorrow),
          findsOneWidget,
          reason: 'on the step result',
        );
        await t.ensureVisible(find.byKey(const Key('station-continue')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('station-continue')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
        expect(
          find.text(_fromTomorrow),
          findsOneWidget,
          reason: 'on the day-complete sheet',
        );
      },
    );

    testWidgets('a completion without levelChange shows no such line', (
      t,
    ) async {
      await t.pumpWidget(
        _flow(const StationResult(score: 2, total: 3, packComplete: true)),
      );
      await _finishStation(t);
      expect(find.byKey(const Key('level-change-line')), findsNothing);
      await t.tap(find.byKey(const Key('station-continue')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
      expect(find.byKey(const Key('level-change-line')), findsNothing);
    });
  });

  testWidgets('finishing a level check refetches the pack', (t) async {
    var fetches = 0;
    late WidgetRef capturedRef;
    await t.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            ref.watch(dailyPackProvider);
            return Scaffold(
              body: TextButton(
                key: const Key('open'),
                onPressed: () => openPlacement(
                  context,
                  ref,
                  screen: (onLevelSet) => PlacementScreen(
                    onLevelSet: onLevelSet,
                    load: () async => [
                      const PackCheck(prompt: 'Q0', options: ['a', 'b']),
                    ],
                    submit: (_) async => {'level': 'B1', 'correct': 1},
                  ),
                ),
                child: const Text('go'),
              ),
            );
          },
        ),
        overrides: [
          dailyPackProvider.overrideWith((ref) async {
            fetches++;
            return _pack();
          }),
        ],
      ),
    );
    await t.pumpAndSettle();
    expect(fetches, 1);
    await t.tap(find.byKey(const Key('open')));
    await t.pumpAndSettle();
    expect(fetches, 1, reason: 'opening the check refetches nothing');
    await t.tap(find.byKey(const Key('check-q0-opt1')));
    await t.pumpAndSettle();
    // Result screen is showing: the learner has not left it yet.
    expect(find.byKey(const Key('placement-level')), findsOneWidget);
    expect(
      fetches,
      2,
      reason: 'refetched as soon as the level check completed',
    );
    expect(capturedRef, isNotNull);
  });
}
