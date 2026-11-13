import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewers_sheet.dart';
import 'package:bananatalk_app/services/stories_service.dart';

Map<String, dynamic> _view(String id, String name, {bool? completed}) => {
      '_id': 'v$id',
      'user': {'_id': id, 'name': name},
      'viewedAt': DateTime.now().toIso8601String(),
      if (completed != null) 'completed': completed,
    };

void _serve({Map<String, dynamic>? summary, List<Map<String, dynamic>>? views}) {
  StoriesService.httpClient = MockClient((req) async {
    if (req.url.path.endsWith('/views')) {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'viewCount': 2,
            'views': views ??
                [_view('u1', 'Ann', completed: true), _view('u2', 'Bob')],
            if (summary != null) 'summary': summary,
          },
        }),
        200,
      );
    }
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {'reactionCount': 0, 'reactions': []},
      }),
      200,
    );
  });
}

Future<void> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: StoryViewersSheet(storyId: 's1', initialViewCount: 2),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Map<String, dynamic> _summary({Map<String, dynamic>? sticker}) => {
      'views': 12,
      'completions': 7,
      'replies': 3,
      'reactions': 5,
      'sticker': sticker,
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 't'}));
  tearDown(() => StoriesService.httpClient = null);

  testWidgets('no summary: exactly the old sheet', (tester) async {
    _serve(views: [_view('u1', 'Ann'), _view('u2', 'Bob')]);
    await _open(tester);
    expect(find.text('Seen by 2'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.byKey(const Key('story-insights-summary')), findsNothing);
    expect(find.byKey(const Key('story-viewer-completed')), findsNothing);
    expect(find.text('Ann'), findsOneWidget);
  });

  testWidgets('no summary: the completed mark still shows for a completed viewer',
      (tester) async {
    _serve();
    await _open(tester);
    expect(find.byKey(const Key('story-viewer-completed')), findsOneWidget);
    expect(find.byKey(const Key('story-insights-summary')), findsNothing);
  });

  testWidgets('summary numbers render', (tester) async {
    _serve(summary: _summary());
    await _open(tester);
    expect(find.byKey(const Key('story-insights-summary')), findsOneWidget);
    expect(find.text('12 views'), findsOneWidget);
    expect(find.text('7 watched to the end'), findsOneWidget);
    expect(find.text('3 replies'), findsOneWidget);
    expect(find.text('5 reactions'), findsOneWidget);
    expect(find.byKey(const Key('story-insights-sticker')), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('quiz marks the correct option and shows correctCount',
      (tester) async {
    _serve(summary: _summary(sticker: {
      'type': 'quiz',
      'count': 6,
      'correctIndex': 1,
      'correctCount': 4,
      'options': [
        {'text': 'Alpha', 'count': 2},
        {'text': 'Beta', 'count': 4},
      ],
    }));
    await _open(tester);
    expect(find.byKey(const Key('story-insights-sticker')), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('4 answered correctly'), findsOneWidget);
    expect(find.byKey(const Key('story-insights-correct-1')), findsOneWidget);
    expect(find.byKey(const Key('story-insights-correct-0')), findsNothing);
  });

  testWidgets('poll shows each option with its count', (tester) async {
    _serve(summary: _summary(sticker: {
      'type': 'poll',
      'count': 9,
      'options': [
        {'text': 'Cats', 'count': 5},
        {'text': 'Dogs', 'count': 4},
      ],
    }));
    await _open(tester);
    expect(find.text('Cats'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Dogs'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byKey(const Key('story-insights-correct-0')), findsNothing);
  });

  testWidgets('correction shows only the count', (tester) async {
    _serve(summary: _summary(sticker: {'type': 'correction', 'count': 1}));
    await _open(tester);
    expect(find.text('1 correction'), findsOneWidget);
  });

  testWidgets('question box shows the response count', (tester) async {
    _serve(summary: _summary(sticker: {'type': 'questionBox', 'count': 8}));
    await _open(tester);
    expect(find.byKey(const Key('story-insights-sticker')), findsOneWidget);
    expect(find.textContaining('8'), findsWidgets);
  });

  testWidgets('word sticker and unknown type show no block', (tester) async {
    for (final s in [
      {'type': 'word', 'count': 0},
      {'type': 'hologram', 'count': 3},
    ]) {
      _serve(summary: _summary(sticker: s));
      await _open(tester);
      expect(find.byKey(const Key('story-insights-summary')), findsOneWidget);
      expect(find.byKey(const Key('story-insights-sticker')), findsNothing);
    }
  });

  testWidgets('summary with no viewers still shows, plus the empty text',
      (tester) async {
    _serve(summary: _summary(), views: const []);
    await _open(tester);
    expect(find.byKey(const Key('story-insights-summary')), findsOneWidget);
    expect(find.text('No views yet'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('no overflow at 320x480 with long options ($locale)',
        (tester) async {
      final long = 'A very long option text ' * 6;
      _serve(summary: {
        'views': 123456,
        'completions': 98765,
        'replies': 4321,
        'reactions': 12345,
        'sticker': {
          'type': 'quiz',
          'count': 100,
          'correctIndex': 0,
          'correctCount': 60,
          'options': [
            {'text': long, 'count': 60},
            {'text': long, 'count': 40},
          ],
        },
      });
      await _open(tester, locale: locale, size: const Size(320, 480));
      expect(find.byKey(const Key('story-insights-summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
