import 'dart:convert';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/archive/story_archive_screen.dart';
import 'package:bananatalk_app/pages/stories/insights/story_insights_screen.dart';
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

Widget _app(String initial) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/story-insights/:storyId',
        builder: (_, s) =>
            StoryInsightsScreen(storyId: s.pathParameters['storyId']!),
      ),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login'))),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
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
