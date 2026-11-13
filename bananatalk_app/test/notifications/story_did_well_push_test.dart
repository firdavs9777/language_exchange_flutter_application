import 'dart:convert';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/archive/story_archive_screen.dart';
import 'package:bananatalk_app/pages/stories/insights/story_insights_screen.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewers_sheet.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(
  String initial, {
  List<NavigatorObserver> observers = const [],
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: initial,
    observers: observers,
    routes: [
      GoRoute(
        path: '/story-insights/:storyId',
        builder: (_, s) =>
            StoryInsightsScreen(storyId: s.pathParameters['storyId']!),
      ),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login'))),
    ],
  );
  final app = MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

void main() {
  tearDown(() => StoriesService.httpClient = null);

  group('story_did_well routing', () {
    test('opens the story insights', () {
      expect(
        NotificationRouter.targetPathForType('story_did_well', {'storyId': 's1'}),
        '/story-insights/s1',
      );
      expect(
        NotificationRouter.planFor('story_did_well', {'storyId': 's1'}).usePushAfterHome,
        isTrue,
      );
    });

    test('a bare route to the insights is not pushed unvalidated', () {
      expect(
        NotificationRouter.targetPathForType(
            'something_new', {'route': '/story-insights/a/b'}),
        isNull,
      );
    });

    test('a missing or malformed id opens the Moments tab', () {
      for (final data in <Map<String, dynamic>>[
        {},
        {'storyId': ''},
        {'storyId': '  '},
        {'storyId': 'a/b'},
        {'storyId': '../x?y'},
      ]) {
        expect(NotificationRouter.targetPathForType('story_did_well', data), '/tabs/3');
      }
    });
  });

  group('StoryInsightsScreen', () {
    testWidgets('shows the summary when the views load', (t) async {
      SharedPreferences.setMockInitialValues({'token': 't'});
      StoriesService.httpClient = MockClient((req) async {
        if (req.url.path.endsWith('/views')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'viewCount': 2,
                'views': const [],
                'summary': {
                  'views': 12,
                  'completions': 7,
                  'replies': 3,
                  'reactions': 5,
                  'sticker': null,
                },
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });
      await t.pumpWidget(_app('/story-insights/s1'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('story-insights-summary')), findsOneWidget);
      expect(find.byType(StoryArchiveScreen), findsNothing);
    });

    MockClient oneViewer() => MockClient((req) async {
          if (req.url.path.endsWith('/views')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'viewCount': 1,
                  'views': [
                    {
                      '_id': 'v1',
                      'user': {'_id': 'u2', 'name': 'Ana'},
                      'viewedAt': '2026-11-12T10:00:00.000Z',
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        });

    testWidgets('fills the page: no draggable half-height sheet', (t) async {
      SharedPreferences.setMockInitialValues({'token': 't'});
      StoriesService.httpClient = oneViewer();
      await t.pumpWidget(_app('/story-insights/s1'));
      await t.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      final body = t.getSize(find.byType(StoryViewersSheet));
      final scaffoldBody = t.getSize(find.byType(Scaffold).first);
      expect(body.height, greaterThan(scaffoldBody.height * 0.8));
    });

    testWidgets('tapping a viewer opens the profile on top of the insights',
        (t) async {
      SharedPreferences.setMockInitialValues({'token': 't'});
      StoriesService.httpClient = oneViewer();
      final observer = _Recorder();
      // Never disposed: the real profile page starts app-wide providers
      // whose teardown is not under test here.
      final container = ProviderContainer();
      await t.pumpWidget(_app('/story-insights/s1',
          observers: [observer], container: container));
      await t.pumpAndSettle();
      observer.events.clear();

      await t.tap(find.text('Ana'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      // The profile page may need services a test has not got; only the
      // navigation is under test here.
      while (t.takeException() != null) {}

      expect(observer.events, isNot(contains('pop')),
          reason: 'the insights route must stay under the profile');
      expect(observer.events, contains('push'));
      expect(find.byType(StoryInsightsScreen, skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('falls back to the archive when the views fail', (t) async {
      SharedPreferences.setMockInitialValues({'token': 't'});
      StoriesService.httpClient =
          MockClient((req) async => http.Response('{"success":false}', 500));
      await t.pumpWidget(_app('/story-insights/s1'));
      await t.pumpAndSettle();
      expect(find.byType(StoryArchiveScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('signed out goes to login', (t) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(_app('/story-insights/s1'));
      await t.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });
  });
}

class _Recorder extends NavigatorObserver {
  final events = <String>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('push');
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('pop');
}
