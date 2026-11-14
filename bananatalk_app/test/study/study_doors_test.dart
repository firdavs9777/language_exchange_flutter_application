import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart' hide WeakArea;
import 'package:bananatalk_app/pages/learning/main/sections/progress_card.dart';
import 'package:bananatalk_app/pages/learning/main/sections/recommended_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_doors.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/sections/today_pack_row.dart';
import 'package:bananatalk_app/pages/learning/main/sections/vocab_packs_card.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/pages/learning/main/study_more_screen.dart';
import 'package:bananatalk_app/pages/learning/my_words/my_words_screen.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/my_words_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';
import 'package:bananatalk_app/widgets/guides/page_guide.dart';

const _pack = DailyPack(
  needsLanguage: false,
  dateKey: '2026-11-14',
  weekKey: '2026-W46',
  dayInWeek: 2,
  requestedLevel: 'A2',
  servedLevel: 'A2',
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

AppConfig _cfg({required bool doors, bool fromChats = false}) => AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  studyHubEnabled: true,
  studyDoorsEnabled: doors,
  studyFromChatsEnabled: fromChats,
);

MyWords _words(int candidates, int mistakes, {int due = 9}) => MyWords(
  candidateCount: candidates,
  mistakeCount: mistakes,
  dueWords: due,
  candidates: const [],
  mistakes: const [],
);

Community _freshUser() => Community(
  id: 'me',
  appleId: '',
  googleId: '',
  name: 'Me',
  email: '',
  mbti: '',
  bloodType: '',
  bio: '',
  images: const [],
  birth_day: '',
  birth_month: '',
  gender: '',
  birth_year: '',
  native_language: 'English',
  language_to_learn: 'Korean',
  imageUrls: const [],
  createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
  version: 0,
  followers: const [],
  followings: const [],
  location: Location.defaultLocation(),
);

/// [guide]: a first-week learner, so the hub's guide card shows.
List<Override> _common({
  required bool doors,
  MyWords? words,
  bool fromChats = false,
  bool guide = false,
}) => [
  appConfigProvider.overrideWith(
    (ref) async => _cfg(doors: doors, fromChats: fromChats),
  ),
  dailyPackProvider.overrideWith((ref) async => _pack),
  learningProgressProvider.overrideWith(
    (ref) async => LearningProgress.fromJson({
      'totalXP': 1,
      'level': 1,
      'currentStreak': 1,
      'dailyXP': 1,
      'dailyGoal': 50,
    }),
  ),
  if (guide) ...[
    userProvider.overrideWith((ref) async => _freshUser()),
    activationDoneProvider.overrideWith((ref) => Stream.value(const {})),
    guideStateProvider(GuideSurface.aiStudy).overrideWith(
      (ref) async => const GuideState(acted: false, timesShown: 0),
    ),
  ] else
    userProvider.overrideWith((ref) => Completer<Community>().future),
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
  featureSeenProvider.overrideWith((ref) async => const <String>{}),
  showAdsProvider.overrideWithValue(false),
  myWordsProvider.overrideWith(
    (ref) => words != null ? Future.value(words) : Completer<MyWords>().future,
  ),
];

Future<void> _pumpHub(
  WidgetTester t, {
  required bool doors,
  MyWords? words,
  bool guide = false,
  Size size = const Size(390, 3000),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: _common(doors: doors, words: words, guide: guide),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StudyHub(),
      ),
    ),
  );
  await t.pump();
  await t.pump();
}

Future<void> _pumpDoor(
  WidgetTester t,
  Widget child, {
  MyWords? words,
  bool fromChats = false,
  ThemeData? theme,
  double textScale = 1.0,
}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: _common(doors: true, words: words, fromChats: fromChats),
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await t.pump();
  await t.pump();
}

Finder _tile(StudyFeature f) =>
    find.byWidgetPredicate((w) => w is StudyFeatureTile && w.feature == f);

double _top(WidgetTester t, Finder f) => t.getRect(f).top;

/// WCAG contrast ratio of text colour [a] (blended over [b]) on [b].
double _contrast(Color a, Color b) {
  final la = Color.alphaBlend(a, b).computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => studyLogSpy = null);

  testWidgets("doors off: the hub column has today's widgets in today's "
      'order and no door', (t) async {
    await _pumpHub(t, doors: false);
    expect(find.byType(MyWordsDoorCard), findsNothing);
    expect(find.byType(TalkDoorCard), findsNothing);
    expect(find.byType(MoreDoorRow), findsNothing);
    final order = [
      find.byType(TodayPackRow),
      find.byType(VocabPacksCard),
      find.byType(RecommendedTile),
      find.byType(StudyFeatureGroups),
      find.byType(ProgressCard),
    ];
    for (final f in order) {
      expect(f, findsOneWidget);
    }
    // VocabPacksCard and RecommendedTile are present (the latter draws
    // nothing without a weak area, so only check the ones with height).
    final tops = [
      _top(t, order[0]),
      _top(t, order[1]),
      _top(t, order[3]),
      _top(t, order[4]),
    ];
    expect([...tops]..sort(), tops);
    // The column's children, in order, exactly as before the doors.
    final column = t.widget<Column>(
      find
          .ancestor(of: find.byType(ProgressCard), matching: find.byType(Column))
          .first,
    );
    expect([for (final w in column.children) w.runtimeType], [
      PageGuide,
      TodayPackRow,
      SizedBox,
      VocabPacksCard,
      SizedBox,
      RecommendedTile,
      SizedBox,
      KeyedSubtree,
      SizedBox,
      ProgressCard,
    ]);
    expect(find.byKey(StudyHub.groupsSectionKey), findsOneWidget);
    // The whole feature grid is there, tutor and roleplay included.
    for (final f in StudyFeature.values) {
      expect(_tile(f), findsOneWidget, reason: f.slug);
    }
  });

  testWidgets('doors on: Today, My words, Talk, More, Progress in that order; '
      'no feature grid', (t) async {
    await _pumpHub(t, doors: true, words: _words(2, 1));
    expect(find.byType(StudyFeatureGroups), findsNothing);
    expect(find.byType(VocabPacksCard), findsNothing);
    expect(find.byType(RecommendedTile), findsNothing);
    expect(find.byKey(StudyHub.groupsSectionKey), findsNothing);
    final order = [
      find.byType(TodayPackRow),
      find.byType(MyWordsDoorCard),
      find.byType(TalkDoorCard),
      find.byType(MoreDoorRow),
      find.byType(ProgressCard),
    ];
    for (final f in order) {
      expect(f, findsOneWidget);
    }
    final tops = [for (final f in order) _top(t, f)];
    expect([...tops]..sort(), tops);
    expect(tops.toSet().length, 5);
  });

  for (final c in [
    (2, 1, '2 words, 1 mistake to look at'),
    (3, 0, '3 words to look at'),
    (0, 1, '1 mistake to look at'),
    (0, 0, '9 words are ready'),
  ]) {
    testWidgets('the my-words card with ${c.$1} words, ${c.$2} mistakes says '
        '"${c.$3}"', (t) async {
      await _pumpDoor(t, const MyWordsDoorCard(), words: _words(c.$1, c.$2));
      expect(find.text(c.$3), findsOneWidget);
    });
  }

  testWidgets('nothing waiting and nothing due: the "will appear here" line '
      'only with studyFromChatsEnabled on', (t) async {
    await _pumpDoor(
      t,
      const MyWordsDoorCard(),
      words: _words(0, 0, due: 0),
      fromChats: true,
    );
    expect(
      find.text('Words you look up in chats will appear here'),
      findsOneWidget,
    );
  });

  testWidgets('nothing waiting, nothing due, switch off: the title alone', (
    t,
  ) async {
    await _pumpDoor(t, const MyWordsDoorCard(), words: _words(0, 0, due: 0));
    expect(find.text('My words and mistakes'), findsOneWidget);
    expect(find.textContaining('appear here'), findsNothing);
    expect(find.textContaining('ready'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('the my-words card has its own colours and readable text '
        '(${brightness.name})', (t) async {
      await _pumpDoor(
        t,
        const MyWordsDoorCard(),
        words: _words(2, 1),
        theme: ThemeData(brightness: brightness),
      );
      final ink = t.widget<Ink>(
        find.descendant(
          of: find.byType(MyWordsDoorCard),
          matching: find.byType(Ink),
        ),
      );
      final colors = (ink.decoration! as BoxDecoration).gradient!.colors;
      // Not the vocab-packs card's gradient.
      expect(colors, isNot([const Color(0xFF0EA5E9), const Color(0xFF14B8A6)]));
      for (final text in [
        'My words and mistakes',
        '2 words, 1 mistake to look at',
      ]) {
        final style = t.widget<Text>(find.text(text)).style!;
        for (final bg in colors) {
          expect(
            _contrast(style.color!, bg),
            greaterThanOrEqualTo(4.5),
            reason: '"$text" on $bg',
          );
        }
      }
    });
  }

  testWidgets('the my-words emoji box does not clip at text scale 1.3', (
    t,
  ) async {
    await _pumpDoor(
      t,
      const MyWordsDoorCard(),
      words: _words(2, 1),
      textScale: 1.3,
    );
    expect(t.takeException(), isNull);
    final emoji = find.text('📝');
    final box = find
        .ancestor(of: emoji, matching: find.byType(Container))
        .first;
    final e = t.getRect(emoji);
    final b = t.getRect(box);
    expect(b.top, lessThanOrEqualTo(e.top));
    expect(b.bottom, greaterThanOrEqualTo(e.bottom));
    expect(b.left, lessThanOrEqualTo(e.left));
    expect(b.right, greaterThanOrEqualTo(e.right));
  });

  testWidgets('door titles may wrap to two lines', (t) async {
    await _pumpDoor(
      t,
      const Column(children: [MyWordsDoorCard(), TalkDoorCard(), MoreDoorRow()]),
      words: _words(2, 1),
    );
    for (final title in ['My words and mistakes', 'Talk', 'More ways to study']) {
      expect(t.widget<Text>(find.text(title)).maxLines, 2, reason: title);
    }
  });

  testWidgets('the Roleplay button is at least 44 tall', (t) async {
    await _pumpDoor(t, const TalkDoorCard());
    expect(
      t.getSize(find.byKey(const Key('study-door-roleplay'))).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('first week, doors off: the guide\'s "See all features" scrolls '
      'to the feature grid', (t) async {
    await _pumpHub(t, doors: false, guide: true, size: const Size(390, 800));
    await t.pump();
    final scrollable = t.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);
    await t.tap(find.text('See all features'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.byType(StudyMoreScreen), findsNothing);
  });

  testWidgets('first week, doors on: the guide\'s "See all features" opens '
      'the More screen', (t) async {
    await _pumpHub(t, doors: true, guide: true, words: _words(2, 1));
    await t.pump();
    await t.tap(find.text('See all features'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(StudyMoreScreen), findsOneWidget);
  });

  testWidgets('the my-words card shows only its title while loading', (
    t,
  ) async {
    await _pumpDoor(t, const MyWordsDoorCard());
    expect(find.text('My words and mistakes'), findsOneWidget);
    expect(find.textContaining('to look at'), findsNothing);
    expect(find.textContaining('appear here'), findsNothing);
  });

  testWidgets('tapping the my-words card opens MyWordsScreen', (t) async {
    await _pumpDoor(t, const MyWordsDoorCard(), words: _words(2, 1));
    await t.tap(find.byType(MyWordsDoorCard));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(MyWordsScreen), findsOneWidget);
  });

  testWidgets('Talk with no persona opens the persona picker, and logs the '
      'tutor slug', (t) async {
    final logged = <Map<String, Object?>>[];
    studyLogSpy = (name, fields) {
      if (name == StudyEvent.featureOpened) logged.add(fields);
    };
    final pushed = <String>[];
    await _pumpDoor(
      t,
      TalkDoorCard(navigate: (_, w) => pushed.add(w.runtimeType.toString())),
    );
    await t.tap(find.text('Talk'));
    await t.pump();
    expect(pushed, ['PersonaPickerScreen']);
    expect(logged.single['kind'], 'tutor');
  });

  testWidgets('the Roleplay button opens roleplay through the same path', (
    t,
  ) async {
    final logged = <Object?>[];
    studyLogSpy = (name, fields) {
      if (name == StudyEvent.featureOpened) logged.add(fields['kind']);
    };
    final pushed = <String>[];
    await _pumpDoor(
      t,
      TalkDoorCard(navigate: (_, w) => pushed.add(w.runtimeType.toString())),
    );
    await t.tap(find.text('Roleplay'));
    await t.pump();
    // Roleplay is a Talk feature: the picker comes first without a persona.
    expect(pushed, ['PersonaPickerScreen']);
    expect(logged, ['roleplay']);
  });

  testWidgets('the More row logs kind more and opens the More screen', (
    t,
  ) async {
    final logged = <Object?>[];
    studyLogSpy = (name, fields) {
      if (name == StudyEvent.featureOpened) logged.add(fields['kind']);
    };
    await _pumpDoor(t, const MoreDoorRow());
    await t.tap(find.byType(MoreDoorRow));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(StudyMoreScreen), findsOneWidget);
    expect(logged, ['more']);
  });

  testWidgets('More lists every feature except tutor and roleplay', (t) async {
    t.view.physicalSize = const Size(390, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: _common(doors: true),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StudyMoreScreen(),
        ),
      ),
    );
    await t.pump();
    await t.pump();
    final l = AppLocalizations.of(t.element(find.byType(StudyMoreScreen)))!;
    expect(find.byType(VocabPacksCard), findsOneWidget);
    expect(find.byType(RecommendedTile), findsOneWidget);
    // Talk group keeps story and photo only; the others are all there.
    expect(find.text(l.studyDoorMore), findsOneWidget);
    expect(_tile(StudyFeature.tutor), findsNothing);
    expect(_tile(StudyFeature.roleplay), findsNothing);
    for (final f in StudyFeature.values) {
      if (f == StudyFeature.tutor || f == StudyFeature.roleplay) continue;
      expect(_tile(f), findsOneWidget, reason: f.slug);
    }
  });

  testWidgets('a group left with no features is not drawn', (t) async {
    t.view.physicalSize = const Size(390, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: _common(doors: true),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudyFeatureGroups(
                exclude: {...studyFeatureGroups[StudyGroup.talk]!},
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    expect(_tile(StudyFeature.tutor), findsNothing);
    expect(_tile(StudyFeature.story), findsNothing);
    expect(_tile(StudyFeature.speak), findsOneWidget);
    final l = AppLocalizations.of(t.element(find.byType(StudyFeatureGroups)))!;
    expect(find.text(l.studyGroupTalk.toUpperCase()), findsNothing);
  });

  testWidgets('StudyFeatureGroups with no exclude draws what it draws today', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: _common(doors: false),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: StudyFeatureGroups()),
          ),
        ),
      ),
    );
    await t.pump();
    for (final f in StudyFeature.values) {
      expect(_tile(f), findsOneWidget);
    }
  });
}
